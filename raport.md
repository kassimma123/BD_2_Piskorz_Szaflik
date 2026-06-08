# Projekt - spiżarnia

**Imiona i nazwiska:** Iga Szaflik, Katarzyna Piskorz

## Schemat Bazy danych

![spizarnia](spizarnia.png)

### `Users` (Użytkownicy)
Tabela przechowuje informacje o użytkownikach systemu (np. domownikach, kucharzach), którzy mogą modyfikować stany magazynowe lub dokonywać rezerwacji posiłków.

```sql
CREATE TABLE Users (
    User_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    First_Name VARCHAR2(50) NOT NULL,
    Last_Name VARCHAR2(50) NOT NULL,
    Role VARCHAR2(20) NOT NULL
);
```
| Nazwa kolumny | Typ danych | Ograniczenia | Opis |
| :--- | :--- | :--- | :--- |
| **`User_ID`** | `NUMBER` | `PRIMARY KEY`, `IDENTITY` | Unikalny identyfikator użytkownika (Klucz główny, autoinkrementacja). |
| **`First_Name`** | `VARCHAR2(50)` | `NOT NULL` | Imię użytkownika. |
| **`Last_Name`** | `VARCHAR2(50)` | `NOT NULL` | Nazwisko użytkownika. |
| **`Role`** | `VARCHAR2(20)` | `NOT NULL` | Rola w systemie (np. 'ADMIN', 'USER', 'CHEF'). |

### `Product_Catalog` (Katalog Produktów)
Słownik wszystkich produktów, które mogą pojawić się w spiżarni lub w przepisach. Definiuje podstawowe właściwości produktu.
```sql
CREATE TABLE Product_Catalog (
    Product_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Product_Name VARCHAR2(100) NOT NULL,
    Unit VARCHAR2(10) NOT NULL,
    Min_Stock_Level NUMBER NOT NULL,
);
```
| Nazwa kolumny | Typ danych | Ograniczenia | Opis |
| :--- | :--- | :--- | :--- |
| **`Product_ID`** | `NUMBER` | `PRIMARY KEY`, `IDENTITY` | Unikalny identyfikator produktu. |
| **`Product_Name`** | `VARCHAR2(100)`| `NOT NULL` | Nazwa produktu (np. "Mleko 3,2%", "Mąka pszenna"). |
| **`Unit`** | `VARCHAR2(10)` | `NOT NULL` | Jednostka miary (np. 'kg', 'litr', 'szt'). |
| **`Min_Stock_Level`**| `NUMBER` | `NOT NULL` | Minimalny próg zapasu. Spadek poniżej tej wartości może generować wpis na listę zakupów. |

### `Inventory` (Spiżarnia / Stany Magazynowe)
Tabela przechowuje fizyczne stany magazynowe. Rekordy reprezentują konkretne partie produktów.
```sql
CREATE TABLE Inventory (
    Batch_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Product_ID NUMBER NOT NULL,
    Quantity NUMBER NOT NULL,
    Expiration_Date DATE NOT NULL,
    Status VARCHAR2(20) NOT NULL,
    FOREIGN KEY (Product_ID) REFERENCES Product_Catalog(Product_ID),
    Reserved_Quantity NUMBER DEFAULT 0 NOT NULL
);
```
| Nazwa kolumny | Typ danych | Ograniczenia | Opis |
| :--- | :--- | :--- | :--- |
| **`Batch_ID`** | `NUMBER` | `PRIMARY KEY`, `IDENTITY` | Unikalny identyfikator partii produktu. |
| **`Product_ID`** | `NUMBER` | `FOREIGN KEY`, `NOT NULL` | Odniesienie do produktu w `Product_Catalog`. |
| **`Quantity`** | `NUMBER` | `NOT NULL` | Aktualna, fizyczna ilość produktu w tej partii. |
| **`Expiration_Date`**| `DATE` | `NOT NULL` | Data ważności danej partii. |
| **`Status`** | `VARCHAR2(20)` | `NOT NULL` | Status partii (np. 'FRESH', 'EXPIRED', 'OPENED'). |
| **`Reserved_Quantity`**|`NUMBER` | `NOT NULL`, `DEFAULT 0`| Ilość produktu z tej partii zarezerwowana na poczet zaplanowanych dań. |

### `Dishes` (Dania w menu)
Słownik dostępnych dań, które można przygotować korzystając z produktów w spiżarni.
```sql
CREATE TABLE Dishes (
    Dish_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Dish_Name VARCHAR2(100) NOT NULL,
    Category VARCHAR2(50) NOT NULL
);
```
| Nazwa kolumny | Typ danych | Ograniczenia | Opis |
| :--- | :--- | :--- | :--- |
| **`Dish_ID`** | `NUMBER` | `PRIMARY KEY`, `IDENTITY` | Unikalny identyfikator dania. |
| **`Dish_Name`** | `VARCHAR2(100)`| `NOT NULL` | Nazwa dania (np. "Spaghetti Bolognese"). |
| **`Category`** | `VARCHAR2(50)` | `NOT NULL` | Kategoria dania (np. 'ZUPA', 'DANIE GŁÓWNE', 'DESER'). |

### `Recipes` (Przepisy)
Tabela łącząca dania z produktami. Określa listę składników (oraz ich ilości) wymaganych do przygotowania konkretnego dania.
```sql
CREATE TABLE Recipes (
    Recipe_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Dish_ID NUMBER NOT NULL,
    Product_ID NUMBER NOT NULL,
    Required_Quantity NUMBER NOT NULL,
    FOREIGN KEY (Dish_ID) REFERENCES Dishes(Dish_ID),
    FOREIGN KEY (Product_ID) REFERENCES Product_Catalog(Product_ID)
);
```
| Nazwa kolumny | Typ danych | Ograniczenia | Opis |
| :--- | :--- | :--- | :--- |
| **`Recipe_ID`** | `NUMBER` | `PRIMARY KEY`, `IDENTITY` | Unikalny identyfikator wpisu w przepisie. |
| **`Dish_ID`** | `NUMBER` | `FOREIGN KEY`, `NOT NULL` | Odniesienie do dania w tabeli `Dishes`. |
| **`Product_ID`** | `NUMBER` | `FOREIGN KEY`, `NOT NULL` | Odniesienie do wymaganego produktu (`Product_Catalog`). |
| **`Required_Quantity`**| `NUMBER` | `NOT NULL` | Ilość produktu potrzebna do przygotowania porcji dania. |

### `Shopping_List` (Lista Zakupów)
Rejestr brakujących produktów, które należy dokupić. 
```sql
CREATE TABLE Shopping_List (
    Shopping_List_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Product_ID NUMBER NOT NULL,
    Date_Added DATE DEFAULT SYSDATE,
    Status VARCHAR2(20) DEFAULT 'TO_BUY',
    FOREIGN KEY (Product_ID) REFERENCES Product_Catalog(Product_ID)
);
```
| Nazwa kolumny | Typ danych | Ograniczenia | Opis |
| :--- | :--- | :--- | :--- |
| **`Shopping_List_ID`**| `NUMBER` | `PRIMARY KEY`, `IDENTITY` | Unikalny identyfikator pozycji na liście. |
| **`Product_ID`** | `NUMBER` | `FOREIGN KEY`, `NOT NULL` | Odniesienie do produktu z katalogu. |
| **`Date_Added`** | `DATE` | `DEFAULT SYSDATE` | Data dodania produktu na listę zakupów. |
| **`Status`** | `VARCHAR2(20)` | `DEFAULT 'TO_BUY'` | Status pozycji (np. 'TO_BUY', 'BOUGHT', 'IGNORED'). |

### `Reservations` (Rezerwacje)
Nagłówek rezerwacji. Pozwala zaplanować przygotowanie konkretnego dania, co wiąże się z alokacją składników w spiżarni.
```sql
CREATE TABLE Reservations (
    Reservation_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    User_ID NUMBER NOT NULL,
    Dish_ID NUMBER,
    Reservation_Date DATE DEFAULT SYSDATE,
    Status VARCHAR2(20) DEFAULT 'ACTIVE',
    FOREIGN KEY (User_ID) REFERENCES Users(User_ID),
    FOREIGN KEY (Dish_ID) REFERENCES Dishes(Dish_ID)
);
```
| Nazwa kolumny | Typ danych | Ograniczenia | Opis |
| :--- | :--- | :--- | :--- |
| **`Reservation_ID`** | `NUMBER` | `PRIMARY KEY`, `IDENTITY` | Unikalny identyfikator rezerwacji. |
| **`User_ID`** | `NUMBER` | `FOREIGN KEY`, `NOT NULL` | Użytkownik dokonujący rezerwacji/planujący posiłek. |
| **`Dish_ID`** | `NUMBER` | `FOREIGN KEY` | Danie, które ma zostać przygotowane. |
| **`Reservation_Date`**| `DATE` | `DEFAULT SYSDATE` | Data utworzenia rezerwacji (lub data planowanego posiłku). |
| **`Status`** | `VARCHAR2(20)` | `DEFAULT 'ACTIVE'` | Status rezerwacji (np. 'ACTIVE', 'COMPLETED', 'CANCELLED'). |

### `Reservation_Items` (Szczegóły Rezerwacji)
Tabela przechowująca szczegóły dotyczące produktów i ich ilości zablokowanych na poczet danej rezerwacji.
```sql
CREATE TABLE Reservation_Items (
    Item_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Reservation_ID NUMBER NOT NULL,
    Product_ID NUMBER NOT NULL,
    Quantity NUMBER NOT NULL,
    FOREIGN KEY (Reservation_ID) REFERENCES Reservations(Reservation_ID),
    FOREIGN KEY (Product_ID) REFERENCES Product_Catalog(Product_ID)
);
```
| Nazwa kolumny | Typ danych | Ograniczenia | Opis |
| :--- | :--- | :--- | :--- |
| **`Item_ID`** | `NUMBER` | `PRIMARY KEY`, `IDENTITY` | Unikalny identyfikator pozycji rezerwacji. |
| **`Reservation_ID`** | `NUMBER` | `FOREIGN KEY`, `NOT NULL` | Odniesienie do nagłówka rezerwacji w `Reservations`. |
| **`Product_ID`** | `NUMBER` | `FOREIGN KEY`, `NOT NULL` | Rezerwowany produkt. |
| **`Quantity`** | `NUMBER` | `NOT NULL` | Dokładna zablokowana ilość danego produktu. |

### `Inventory_Log` (Historia)
Tabela logów śledząca wszelkie operacje wykonywane na magazynie. 
```sql
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
```
| Nazwa kolumny | Typ danych | Ograniczenia | Opis |
| :--- | :--- | :--- | :--- |
| **`Log_ID`** | `NUMBER` | `PRIMARY KEY`, `IDENTITY` | Unikalny identyfikator wpisu w logach. |
| **`User_ID`** | `NUMBER` | `FOREIGN KEY`, `NOT NULL` | Użytkownik, który wykonał akcję w spiżarni. |
| **`Product_ID`** | `NUMBER` | `FOREIGN KEY`, `NOT NULL` | Produkt, którego dotyczy zmiana. |
| **`Action_Type`** | `VARCHAR2(50)` | `NOT NULL` | Typ operacji (np. 'ADDED', 'REMOVED', 'SPOILED', 'RESERVED'). |
| **`Quantity_Change`** | `NUMBER` | `NOT NULL` | Wielkość zmiany (+/- ilość dodana lub ujęta). |
| **`Log_Date`** | `DATE` | `DEFAULT SYSDATE` | Dokładny czas wykonania operacji. |

## Triggery


## Procedury

## Widoki