-- użytkownicy
INSERT INTO Users (First_Name, Last_Name, Role) VALUES ('Robert', 'Makłowicz', 'CHEF');
INSERT INTO Users (First_Name, Last_Name, Role) VALUES ('Iga', 'Szaf', 'COOK');
INSERT INTO Users (First_Name, Last_Name, Role) VALUES ('Kasia', 'Pis', 'COOK');

-- produkty
INSERT INTO Product_Catalog (Product_Name, Unit, Min_Stock_Level) VALUES ('Mleko', 'litr', 5);
INSERT INTO Product_Catalog (Product_Name, Unit, Min_Stock_Level) VALUES ('Mąka pszenna', 'kg', 10);
INSERT INTO Product_Catalog (Product_Name, Unit, Min_Stock_Level) VALUES ('Jajka', 'szt', 30);
INSERT INTO Product_Catalog (Product_Name, Unit, Min_Stock_Level) VALUES ('Cukier', 'kg', 3);

-- stan magazynowy
-- Dostawa mleka
INSERT INTO Inventory (Product_ID, Quantity, Expiration_Date, Status, Reserved_Quantity)
VALUES (1, 6, TO_DATE('2026-06-05', 'YYYY-MM-DD'), 'AVAILABLE', 0);
INSERT INTO Inventory (Product_ID, Quantity, Expiration_Date, Status, Reserved_Quantity)
VALUES (1, 10, TO_DATE('2026-06-30', 'YYYY-MM-DD'), 'AVAILABLE', 0);

-- Dostawa mąki
INSERT INTO Inventory (Product_ID, Quantity, Expiration_Date, Status, Reserved_Quantity)
VALUES (2, 15, TO_DATE('2026-12-31', 'YYYY-MM-DD'), 'AVAILABLE', 0);
INSERT INTO Inventory (Product_ID, Quantity, Expiration_Date, Status, Reserved_Quantity)
VALUES (2, 15, TO_DATE('2026-12-31', 'YYYY-MM-DD'), 'AVAILABLE', 0);

-- Dostawa jajek
INSERT INTO Inventory (Product_ID, Quantity, Expiration_Date, Status, Reserved_Quantity)
VALUES (3, 40, TO_DATE('2026-06-15', 'YYYY-MM-DD'), 'AVAILABLE', 0);
INSERT INTO Inventory (Product_ID, Quantity, Expiration_Date, Status, Reserved_Quantity)
VALUES (3, 40, TO_DATE('2026-07-15', 'YYYY-MM-DD'), 'AVAILABLE', 0);

-- menu
INSERT INTO Dishes (Dish_Name, Category) VALUES ('Naleśniki', 'Śniadanie');
INSERT INTO Dishes (Dish_Name, Category) VALUES ('Ciasto Biszkoptowe', 'Deser');

-- przepisy
-- Przepis na Naleśniki
INSERT INTO Recipes (Dish_ID, Product_ID, Required_Quantity) VALUES (1, 1, 2); -- 2l mleka
INSERT INTO Recipes (Dish_ID, Product_ID, Required_Quantity) VALUES (1, 2, 1); -- 1kg mąki
INSERT INTO Recipes (Dish_ID, Product_ID, Required_Quantity) VALUES (1, 3, 4); -- 4 jajka

-- Przepis na Ciasto
INSERT INTO Recipes (Dish_ID, Product_ID, Required_Quantity) VALUES (2, 1, 5); -- 5l mleka (tu braknie jak ktoś weźmie na naleśniki!)
INSERT INTO Recipes (Dish_ID, Product_ID, Required_Quantity) VALUES (2, 2, 2); -- 2kg mąki
INSERT INTO Recipes (Dish_ID, Product_ID, Required_Quantity) VALUES (2, 3, 10); -- 10 jajek

-- Zatwierdzenie zmian w bazie Oracle
COMMIT;