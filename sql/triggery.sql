-- Wyzwalacz historii zmian: TRG_Inventory_History
CREATE OR REPLACE TRIGGER TRG_Inventory_History
AFTER INSERT OR UPDATE OR DELETE ON Inventory
FOR EACH ROW
DECLARE
    v_user_id NUMBER := 1;
    v_action VARCHAR2(50);
    v_qty_change NUMBER;
    v_product_id NUMBER;
BEGIN
    IF INSERTING THEN
        v_action := 'ADDED_NEW_BATCH';
        v_qty_change := :NEW.Quantity;
        v_product_id := :NEW.Product_ID;

    ELSIF UPDATING THEN
        v_product_id := :NEW.Product_ID;

        -- zmiana całkowitej ilości
        IF :NEW.Quantity != :OLD.Quantity THEN
            v_action := 'QUANTITY_CHANGED';
            v_qty_change := :NEW.Quantity - :OLD.Quantity;
        -- zmiana zarezerwowanej ilości
        ELSIF :NEW.Reserved_Quantity != :OLD.Reserved_Quantity THEN
            v_action := 'RESERVATION_UPDATED';
            v_qty_change := :NEW.Reserved_Quantity - :OLD.Reserved_Quantity;
        ELSE
            v_action := 'STATUS_UPDATED (' || :NEW.Status || ')';
            v_qty_change := 0;
        END IF;
    ELSIF DELETING THEN
        v_action := 'REMOVED_BATCH';
        v_qty_change := -:OLD.Quantity;
        v_product_id := :OLD.Product_ID;
    END IF;

    INSERT INTO Inventory_log (User_ID, Product_ID, Action_Type, Quantity_Change, Log_Date)
    VALUES (v_user_id, v_product_id, v_action, v_qty_change, SYSDATE);
END;
/

# TRG_Auto_Restock
CREATE OR REPLACE TRIGGER TRG_Auto_Restock
AFTER UPDATE OF Quantity, Reserved_Quantity ON Inventory
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_Min_Stock NUMBER;
    v_Total_Current_Available NUMBER;
    v_Already_On_List NUMBER;
BEGIN
    -- Sprawdzam w katalogu produktów minimalny próg
    SELECT Min_Stock_Level INTO v_Min_Stock 
    FROM Product_Catalog 
    WHERE Product_ID = :NEW.Product_ID;

    -- Liczę, ile łącznie mamy towaru (teraz to zapytanie zadziała!)
    SELECT NVL(SUM(Quantity - Reserved_Quantity), 0)
    INTO v_Total_Current_Available
    FROM Inventory
    WHERE Product_ID = :NEW.Product_ID AND Status = 'AVAILABLE' AND Expiration_Date >= TRUNC(SYSDATE);

    -- Sprawdzam, czy produkt już nie wisi na liście
    SELECT COUNT(*) 
    INTO v_Already_On_List
    FROM Shopping_List
    WHERE Product_ID = :NEW.Product_ID AND Status = 'TO_BUY';

    -- Dodaję do listy zakupów, jeśli trzeba
    IF v_Total_Current_Available < v_Min_Stock AND v_Already_On_List = 0 THEN
        INSERT INTO Shopping_List (Product_ID, Date_Added, Status)
        VALUES (:NEW.Product_ID, SYSDATE, 'TO_BUY');
    END IF;
    
    -- Wymagane zatwierdzenie przy autonomicznej transakcji
    COMMIT; 
END;
/
