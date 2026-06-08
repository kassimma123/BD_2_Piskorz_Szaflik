# Projekt - spiżarnia

**Imiona i nazwiska:** Iga Szaflik, Katarzyna Piskorz

## Schemat Bazy danych

![spizarnia](spizarnia.png)

### Użytkownicy `Users`
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


## Triggery


## Procedury