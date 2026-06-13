-- Tworzymy dwie role (uruchom to jako administrator, np. użytkownik spizarnia, jeśli ma uprawnienia)
CREATE ROLE ROLE_COOK;
CREATE ROLE ROLE_CHEF;

-- Uprawnienia dla zwykłego kucharza (może tylko rezerwować i przeglądać)
GRANT SELECT ON Dishes TO ROLE_COOK;
GRANT SELECT ON Recipes TO ROLE_COOK;
GRANT SELECT ON Product_Catalog TO ROLE_COOK;
GRANT SELECT, UPDATE ON Inventory TO ROLE_COOK;
GRANT INSERT, SELECT, UPDATE ON Reservations TO ROLE_COOK;
GRANT INSERT, SELECT ON Reservation_Items TO ROLE_COOK;
GRANT EXECUTE ON Zarezerwuj_Danie TO ROLE_COOK;
GRANT EXECUTE ON Resolve_Reservation TO ROLE_COOK;

-- Uprawnienia dla Szefa Kuchni (dziedziczy uprawnienia kucharza + ma pełną władzę nad menu i zamknięciem dnia)
GRANT ROLE_COOK TO ROLE_CHEF;
GRANT INSERT, UPDATE, DELETE ON Dishes TO ROLE_CHEF;
GRANT INSERT, UPDATE, DELETE ON Recipes TO ROLE_CHEF;
GRANT INSERT, UPDATE, DELETE ON Product_Catalog TO ROLE_CHEF;
GRANT EXECUTE ON Koniec_Dnia_Darmowe_Oddanie TO ROLE_CHEF;