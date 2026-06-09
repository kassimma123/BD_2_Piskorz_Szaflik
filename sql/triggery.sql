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