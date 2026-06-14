-- Procedura rozliczania i zwalniania rezerwacji: Resolve_Reservation
CREATE OR REPLACE PROCEDURE Resolve_Reservation(
    p_reservation_id IN NUMBER,
    p_action IN VARCHAR2
)
IS
    v_status VARCHAR2(20);
    v_qty_to_process NUMBER;
    v_deduct NUMBER;

    -- produkty w rezerwacji
    CURSOR c_items IS
        SELECT Product_ID, Quantity
        FROM Reservation_Items
        WHERE Reservation_ID = p_reservation_id;

    CURSOR c_inventory(p_prod NUMBER) IS
        SELECT Batch_ID, Quantity, Reserved_Quantity
        FROM Inventory
        WHERE Product_ID = p_prod AND Reserved_Quantity > 0
        ORDER BY Expiration_Date ASC
        FOR UPDATE; -- blokowanie

BEGIN
    SELECT Status INTO v_status FROM Reservations WHERE Reservation_id = p_reservation_id;

    IF v_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Rezerwacja została już zakończona lub anulowana!');
    END IF;

    FOR item IN c_items LOOP
        v_qty_to_process := item.Quantity;

        FOR inv_batch IN c_inventory(item.Product_ID) LOOP
            EXIT WHEN v_qty_to_process <= 0;

            v_deduct := LEAST(v_qty_to_process, inv_batch.Reserved_Quantity);

            IF p_action = 'COMPLETED' THEN -- ugotowano
                UPDATE Inventory
                SET Quantity = Quantity - v_deduct,
                    Reserved_Quantity = Reserved_Quantity - v_deduct
                WHERE CURRENT OF c_inventory;

            ELSIF p_action = 'CANCELLED' THEN -- anulowano
                UPDATE Inventory
                SET Reserved_Quantity = Reserved_Quantity - v_deduct
                WHERE CURRENT OF c_inventory;
            END IF;

            v_qty_to_process := v_qty_to_process - v_deduct;
        END LOOP;
    END LOOP;

    -- aktualizacja
    UPDATE Reservations
    SET Status = p_action
    WHERE Reservation_ID = p_reservation_id;

    COMMIT; -- zapisujemy

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Nie znaleziono takiej rezerwacji!');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;

END;
/

-- Procedura rezerwacji dania Reserve_Dish
CREATE OR REPLACE PROCEDURE Reserve_Dish (
    p_User_ID IN NUMBER,
    p_Dish_ID IN NUMBER
) AS
    v_Has_Enough_Stock BOOLEAN := TRUE;
    v_Reservation_ID NUMBER;
    v_Available_Qty NUMBER;
    
    -- Wyciągam składniki potrzebne do zrobienia tego konkretnego dania
    CURSOR c_Recipe IS
        SELECT Product_ID, Required_Quantity 
        FROM Recipes 
        WHERE Dish_ID = p_Dish_ID;
        
    -- Tabele pomocnicze, żeby zapamiętać w pamięci sesji co musimy zablokować i ile tego potrzebujemy
    TYPE t_Product_ID IS TABLE OF Recipes.Product_ID%TYPE;
    TYPE t_Required_Qty IS TABLE OF Recipes.Required_Quantity%TYPE;
    v_Prod_IDs t_Product_ID := t_Product_ID();
    v_Req_Qties t_Required_Qty := t_Required_Qty();
BEGIN
    -- BLOKOWANIE I WERYFIKACJA ASORTYMENTU
    -- Przechodzę po kolei przez każdy składnik z przepisu i blokuję go w bazie (FOR UPDATE),
    -- żeby w tym samym czasie nikt inny nie podkradł nam tych produktów ze spiżarni.
    FOR r IN c_Recipe LOOP
        v_Prod_IDs.EXTEND;
        v_Req_Qties.EXTEND;
        v_Prod_IDs(v_Prod_IDs.LAST) := r.Product_ID;
        v_Req_Qties(v_Req_Qties.LAST) := r.Required_Quantity;

        -- Liczę, ile w ogóle mamy wolnego i ważnego produktu we wszystkich partiach.
        SELECT NVL(SUM(Quantity - Reserved_Quantity), 0)
        INTO v_Available_Qty
        FROM Inventory
        WHERE Product_ID = r.Product_ID 
          AND Status = 'AVAILABLE' 
          AND Expiration_Date >= TRUNC(SYSDATE);

        -- Jeśli w spiżarni brakuje chociaż jednego składnika, zaznaczam to sobie na później.
        IF v_Available_Qty < r.Required_Quantity THEN
            v_Has_Enough_Stock := FALSE;
        END IF;
    END LOOP;

    -- DECYZJA O TRANSAKCJI
    IF NOT v_Has_Enough_Stock THEN
        -- Jeśli zabrakło jakiegoś składnika, wycofuję wszystkie blokady (ROLLBACK) i rzucam błąd.
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Brak wystarczającej ilości składników w spiżarni do przygotowania tego dania!');
    ELSE
        -- Jak wszystko jest na stanie, to tworzę główny wpis rezerwacji.
        INSERT INTO Reservations (User_ID, Dish_ID, Reservation_Date, Status)
        VALUES (p_User_ID, p_Dish_ID, SYSDATE, 'ACTIVE')
        RETURNING Reservation_ID INTO v_Reservation_ID;

        -- Teraz po kolei rezerwuję potrzebną ilość każdego składnika w partiach.
        FOR i IN 1..v_Prod_IDs.COUNT LOOP
            -- Zapisuję szczegóły, co dokładnie i w jakiej ilości zostało zarezerwowane dla danej rezerwacji.
            INSERT INTO Reservation_Items (Reservation_ID, Product_ID, Quantity)
            VALUES (v_Reservation_ID, v_Prod_IDs(i), v_Req_Qties(i));

            -- Muszę rozdysponować zapotrzebowanie na partie w magazynie.
            -- Zaczynam od tych partii, które mają najkrótszą datę ważności (FIFO dla przeterminowania).
            DECLARE
                v_Remaining_To_Reserve NUMBER := v_Req_Qties(i);
                v_Batch_ID NUMBER;
                v_Batch_Free_Qty NUMBER;
                
                CURSOR c_Batches IS
                    SELECT Batch_ID, (Quantity - Reserved_Quantity) AS Free_Qty
                    FROM Inventory
                    WHERE Product_ID = v_Prod_IDs(i) 
                      AND Status = 'AVAILABLE' 
                      AND Expiration_Date >= TRUNC(SYSDATE)
                    ORDER BY Expiration_Date ASC
                    FOR UPDATE; -- Blokuję te rekordy żeby nikt inny ich nie użył
            BEGIN
                OPEN c_Batches;
                LOOP
                    FETCH c_Batches INTO v_Batch_ID, v_Batch_Free_Qty;
                    EXIT WHEN c_Batches%NOTFOUND OR v_Remaining_To_Reserve = 0;
                    
                    -- Jeśli ta partia ma więcej wolnego niż potrzebuję, rezerwuję całość i kończę.
                    IF v_Batch_Free_Qty >= v_Remaining_To_Reserve THEN
                        UPDATE Inventory 
                        SET Reserved_Quantity = Reserved_Quantity + v_Remaining_To_Reserve
                        WHERE Batch_ID = v_Batch_ID;
                        v_Remaining_To_Reserve := 0;
                    ELSE
                        -- Jeśli partia ma za mało, rezerwuję ile się da i szukam w kolejnej partii.
                        UPDATE Inventory 
                        SET Reserved_Quantity = Reserved_Quantity + v_Batch_Free_Qty
                        WHERE Batch_ID = v_Batch_ID;
                        v_Remaining_To_Reserve := v_Remaining_To_Reserve - v_Batch_Free_Qty;
                    END IF;
                END LOOP;
                CLOSE c_Batches;
            END;
            
            -- Wrzucam info do logów, że dany użytkownik zablokował składniki.
            INSERT INTO Inventory_Log (User_ID, Product_ID, Action_Type, Quantity_Change)
            VALUES (p_User_ID, v_Prod_IDs(i), 'RESERVATION_ADD', v_Req_Qties(i));
        END LOOP;

        -- Wszystko się udało, zapisuję transakcję i puszczam blokady.
        COMMIT;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; -- W razie nieoczekiwanego błędu bazy danych wycofaj wszystko
        RAISE;
END Zarezerwuj_Danie;
/


-- Procedura końca dnia darmowego oddania - Donate_Expired_Food
CREATE OR REPLACE PROCEDURE Donate_Expired_Food (
    p_Admin_User_ID IN NUMBER
) AS
    v_User_Role VARCHAR2(20);
BEGIN
    -- Upewniam się, czy to na pewno Szef Kuchni (CHEF) odpala procedurę. Zwykły pracownik nie ma uprawnień.
    SELECT Role INTO v_User_Role FROM Users WHERE User_ID = p_Admin_User_ID;
    IF v_User_Role != 'CHEF' THEN
        RAISE_APPLICATION_ERROR(-20002, 'Tylko Szef Kuchni może uruchomić procedurę końca dnia!');
    END IF;

    -- Szukam partii jedzenia, które kończą ważność dzisiaj lub jutro i nie są jeszcze zarezerwowane.
    -- Wszystko to, co jest wolne (Quantity - Reserved_Quantity > 0), oddajemy na cele charytatywne.
    FOR r IN (
        SELECT Batch_ID, Product_ID, (Quantity - Reserved_Quantity) AS Available_To_Donate
        FROM Inventory
        WHERE Expiration_Date <= TRUNC(SYSDATE) + 1 
          AND Status = 'AVAILABLE'
          AND (Quantity - Reserved_Quantity) > 0
    ) LOOP
        -- Zapisuję do logów, ile dokładnie oddaliśmy danej rzeczy na charytatywność (dlatego ujemna wartość).
        INSERT INTO Inventory_Log (User_ID, Product_ID, Action_Type, Quantity_Change)
        VALUES (p_Admin_User_ID, r.Product_ID, 'CHARITY_DONATION', -r.Available_To_Donate);

        -- Zeruję wolne zapasy z tej partii (zostaje tylko to, co już było wcześniej zarezerwowane).
        -- Jeśli po tym zabiegu nic nie zostało zarezerwowane (Reserved_Quantity = 0), oznaczam partię jako całkiem oddaną ('DONATED').
        UPDATE Inventory
        SET Quantity = Reserved_Quantity, 
            Status = CASE WHEN Reserved_Quantity = 0 THEN 'DONATED' ELSE 'AVAILABLE' END
        WHERE Batch_ID = r.Batch_ID;
    END LOOP;
    
    -- Zapisuję zmiany na stałe.
    COMMIT;
END Koniec_Dnia_Darmowe_Oddanie;
/


