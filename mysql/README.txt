How to:

1. Baza MySql (testowane na wersji 5.5.31)
2. Utworzenie bazy danych "slic" z Collation UTF-8!: CREATE DATABASE slic CHARACTER SET utf8 COLLATE utf8_general_ci;
3. Wczytanie pliku all.sql: mysql < all.sql
4. Wywoływanie eksperymentów: CALL ex(n), gdzie n - numer eksperymentu 1..9; 0 - inicjalizacja

CALL ex(0);
CALL ex(1);
CALL ex(2);
CALL ex(3);
CALL ex(4);
CALL ex(5);
CALL ex(6);
CALL ex(7);
CALL ex(8);
CALL ex(9);

5. Generowanie pliku all.sql: cat queires.sql inserts.sql > all.sql 

