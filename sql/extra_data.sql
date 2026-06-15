-- produkty
INSERT INTO Product_Catalog (Product_Name, Unit, Min_Stock_Level) VALUES ('Pomidory', 'kg', 5);
INSERT INTO Product_Catalog (Product_Name, Unit, Min_Stock_Level) VALUES ('Makaron', 'kg', 5);
INSERT INTO Product_Catalog (Product_Name, Unit, Min_Stock_Level) VALUES ('Mięso Mielone', 'kg', 2);
INSERT INTO Product_Catalog (Product_Name, Unit, Min_Stock_Level) VALUES ('Ser Żółty', 'kg', 1);

-- stan magazynowy
INSERT INTO Inventory (Product_ID, Quantity, Expiration_Date, Status, Reserved_Quantity)
VALUES ((SELECT Product_ID FROM Product_Catalog WHERE Product_Name = 'Pomidory'), 10, SYSDATE + 7, 'AVAILABLE', 0);

INSERT INTO Inventory (Product_ID, Quantity, Expiration_Date, Status, Reserved_Quantity)
VALUES ((SELECT Product_ID FROM Product_Catalog WHERE Product_Name = 'Makaron'), 20, SYSDATE + 365, 'AVAILABLE', 0);

INSERT INTO Inventory (Product_ID, Quantity, Expiration_Date, Status, Reserved_Quantity)
VALUES ((SELECT Product_ID FROM Product_Catalog WHERE Product_Name = 'Mięso Mielone'), 4, SYSDATE + 2, 'AVAILABLE', 0);

INSERT INTO Inventory (Product_ID, Quantity, Expiration_Date, Status, Reserved_Quantity)
VALUES ((SELECT Product_ID FROM Product_Catalog WHERE Product_Name = 'Ser Żółty'), 2, SYSDATE + 14, 'AVAILABLE', 0);

-- menu
INSERT INTO Dishes (Dish_Name, Category) VALUES ('Spaghetti Bolognese', 'Obiad');
INSERT INTO Dishes (Dish_Name, Category) VALUES ('Zupa Pomidorowa', 'Zupa');

-- przepisy
-- Spaghetti Bolognese
INSERT INTO Recipes (Dish_ID, Product_ID, Required_Quantity) VALUES ((SELECT Dish_ID FROM Dishes WHERE Dish_Name = 'Spaghetti Bolognese'), (SELECT Product_ID FROM Product_Catalog WHERE Product_Name = 'Pomidory'), 2);
INSERT INTO Recipes (Dish_ID, Product_ID, Required_Quantity) VALUES ((SELECT Dish_ID FROM Dishes WHERE Dish_Name = 'Spaghetti Bolognese'), (SELECT Product_ID FROM Product_Catalog WHERE Product_Name = 'Makaron'), 1);
INSERT INTO Recipes (Dish_ID, Product_ID, Required_Quantity) VALUES ((SELECT Dish_ID FROM Dishes WHERE Dish_Name = 'Spaghetti Bolognese'), (SELECT Product_ID FROM Product_Catalog WHERE Product_Name = 'Mięso Mielone'), 1);

-- Zupa Pomidorowa
INSERT INTO Recipes (Dish_ID, Product_ID, Required_Quantity) VALUES ((SELECT Dish_ID FROM Dishes WHERE Dish_Name = 'Zupa Pomidorowa'), (SELECT Product_ID FROM Product_Catalog WHERE Product_Name = 'Pomidory'), 3);
INSERT INTO Recipes (Dish_ID, Product_ID, Required_Quantity) VALUES ((SELECT Dish_ID FROM Dishes WHERE Dish_Name = 'Zupa Pomidorowa'), (SELECT Product_ID FROM Product_Catalog WHERE Product_Name = 'Makaron'), 1);

COMMIT;
