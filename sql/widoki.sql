-- Widok raportujący: V_Cook_Today
CREATE OR REPLACE VIEW V_Cook_Today AS
WITH Available_Stock AS (
    -- dostępną ilość na półce (minus rezerwacje)
    SELECT
        Product_ID,
        SUM(Quantity - Reserved_Quantity) AS Total_Available,
        MIN(Expiration_Date) AS Soonest_Exp_Date
    FROM Inventory
    WHERE Status = 'AVAILABLE'
      AND Expiration_Date >= SYSDATE
    GROUP BY Product_ID
),
     Dish_Capabilities AS (
         -- Łączymy dania z ich przepisami i naszym magazynem
         SELECT
             d.Dish_ID,
             d.Dish_Name,
             d.Category,
             MIN(FLOOR(NVL(st.Total_Available, 0) / r.Required_Quantity)) AS Max_Portions,
             MIN(st.Soonest_Exp_Date) AS Critical_Expiration_Date -- data ważności
         FROM Dishes d
                  JOIN Recipes r ON d.Dish_ID = r.Dish_ID
                  LEFT JOIN Available_Stock st ON r.Product_ID = st.Product_ID
         GROUP BY d.Dish_ID, d.Dish_Name, d.Category
     )
SELECT
    Dish_ID AS "ID Dania",
    Dish_Name AS "Nazwa Dania",
    Category AS "Kategoria",
    Max_Portions AS "Możliwych Porcji",
    Critical_Expiration_Date AS "Najpilniejszy Składnik"
FROM Dish_Capabilities
WHERE Max_Portions > 0
ORDER BY Critical_Expiration_Date ASC;