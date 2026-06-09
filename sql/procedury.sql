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