-- Indeks na datę ważności
CREATE INDEX idx_inventory_exp_date ON Inventory(Expiration_Date);

-- Indeksy na klucze obce
CREATE INDEX idx_inventory_product_id ON Inventory(Product_ID);
CREATE INDEX idx_recipes_dish_id ON Recipes(Dish_ID);