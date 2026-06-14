-- Indeks do szybkiego wyszukiwania psującego się jedzenia
CREATE INDEX idx_inventory_exp_date ON Inventory(Expiration_Date);

-- Indeksy na klucze obce
CREATE INDEX idx_inventory_product_id ON Inventory(Product_ID);
CREATE INDEX idx_recipes_dish_id ON Recipes(Dish_ID);
CREATE INDEX idx_recipes_product_id ON Recipes(Product_ID);
CREATE INDEX idx_reservations_user_id ON Reservations(User_ID);
CREATE INDEX idx_res_items_res_id ON Reservation_Items(Reservation_ID);
CREATE INDEX idx_res_items_prod_id ON Reservation_Items(Product_ID);
CREATE INDEX idx_log_product_id ON Inventory_Log(Product_ID);