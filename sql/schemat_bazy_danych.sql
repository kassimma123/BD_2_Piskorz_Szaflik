create user spizarnia identified by 123;

grant connect, resource to spizarnia

alter user spizarnia quota unlimited on users;

-- Użytkownicy
CREATE TABLE Users (
    User_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    First_Name VARCHAR2(50) NOT NULL,
    Last_Name VARCHAR2(50) NOT NULL,
    Role VARCHAR2(20) NOT NULL
);

-- Katalog Produktów
CREATE TABLE Product_Catalog (
    Product_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Product_Name VARCHAR2(100) NOT NULL,
    Unit VARCHAR2(10) NOT NULL,
    Min_Stock_Level NUMBER NOT NULL,
);

-- spiżarnia
CREATE TABLE Inventory (
    Batch_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Product_ID NUMBER NOT NULL,
    Quantity NUMBER NOT NULL,
    Expiration_Date DATE NOT NULL,
    Status VARCHAR2(20) NOT NULL,
    FOREIGN KEY (Product_ID) REFERENCES Product_Catalog(Product_ID),
    Reserved_Quantity NUMBER DEFAULT 0 NOT NULL
);

-- dania/menu
CREATE TABLE Dishes (
    Dish_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Dish_Name VARCHAR2(100) NOT NULL,
    Category VARCHAR2(50) NOT NULL
);

-- przepisy
CREATE TABLE Recipes (
    Recipe_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Dish_ID NUMBER NOT NULL,
    Product_ID NUMBER NOT NULL,
    Required_Quantity NUMBER NOT NULL,
    FOREIGN KEY (Dish_ID) REFERENCES Dishes(Dish_ID),
    FOREIGN KEY (Product_ID) REFERENCES Product_Catalog(Product_ID)
);

-- lista zakupów
CREATE TABLE Shopping_List (
    Shopping_List_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Product_ID NUMBER NOT NULL,
    Date_Added DATE DEFAULT SYSDATE,
    Status VARCHAR2(20) DEFAULT 'TO_BUY',
    FOREIGN KEY (Product_ID) REFERENCES Product_Catalog(Product_ID)
);

-- Tabela Rezerwacje
CREATE TABLE Reservations (
    Reservation_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    User_ID NUMBER NOT NULL,
    Dish_ID NUMBER,
    Reservation_Date DATE DEFAULT SYSDATE,
    Status VARCHAR2(20) DEFAULT 'ACTIVE',
    FOREIGN KEY (User_ID) REFERENCES Users(User_ID),
    FOREIGN KEY (Dish_ID) REFERENCES Dishes(Dish_ID)
);

-- Szczegóły Rezerwacji (Konkretne produkty i zablokowane ilości)
CREATE TABLE Reservation_Items (
    Item_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Reservation_ID NUMBER NOT NULL,
    Product_ID NUMBER NOT NULL,
    Quantity NUMBER NOT NULL,
    FOREIGN KEY (Reservation_ID) REFERENCES Reservations(Reservation_ID),
    FOREIGN KEY (Product_ID) REFERENCES Product_Catalog(Product_ID)
);

-- historia
CREATE TABLE Inventory_Log (
    Log_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    User_ID NUMBER NOT NULL,
    Product_ID NUMBER NOT NULL,
    Action_Type VARCHAR2(50) NOT NULL,
    Quantity_Change NUMBER NOT NULL,
    Log_Date DATE DEFAULT SYSDATE,
    FOREIGN KEY (User_ID) REFERENCES Users(User_ID),
    FOREIGN KEY (Product_ID) REFERENCES Product_Catalog(Product_ID)
);