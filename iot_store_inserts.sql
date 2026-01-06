BEGIN;

-- Borrado de datos previo
DELETE FROM FACT_SELLS;
DELETE FROM DIM_CALENDAR;
DELETE FROM DIM_PRODUCTS;
DELETE FROM DIM_CLIENTS;
DELETE FROM DIM_STORES;
DELETE FROM DIM_CITIES;
DELETE FROM DIM_REGIONS;
DELETE FROM DIM_COUNTRIES;
DELETE FROM DIM_CATEGORIES;
DELETE FROM DIM_PROTOCOLS;

-- Inserts de pais, regiones y ciudades
INSERT INTO DIM_COUNTRIES (country_name) VALUES ('United Kingdom'), ('Germany'), ('USA'), ('Japan'), ('Spain'), ('France');

INSERT INTO DIM_REGIONS (region_name, country_id) VALUES 
('Greater London', 1), ('Berlin', 2), ('New York', 3), ('Kanto', 4), ('Île-de-France', 6);

INSERT INTO DIM_CITIES (city_name, region_id) VALUES 
('London', 1), ('Berlin', 2), ('New York City', 3), ('Tokyo', 4), ('Paris', 5);

UPDATE DIM_CITIES SET city_name = 'NYC' WHERE city_name = 'New York City';

-- Inserts de categorias y protocolos
INSERT INTO DIM_CATEGORIES (category_name) VALUES ('Sensor'), ('Actuador'), ('Hub');
INSERT INTO DIM_PROTOCOLS (protocol_name) VALUES ('Zigbee'), ('WiFi'), ('Matter'), ('Thread');

-- Inserts de tiendas y clientes
INSERT INTO DIM_STORES (city_id) VALUES (1), (2), (3), (4), (5);

INSERT INTO DIM_CLIENTS (client_name, email, city_id) VALUES 
('Alice Smith', 'alice@email.com', 3),
('Hans Müller', 'hans@email.de', 2),
('Yuki Tanaka', 'yuki@email.jp', 4),
('Jean Pierre', 'jean@email.fr', 5),
('John Doe', 'john@email.uk', 1);

INSERT INTO DIM_PRODUCTS (product_name, category_id, protocol_id, unit_price) VALUES 
('Smart Thermostat Pro', 2, 3, 199.99),
('Motion Sensor Eco', 1, 1, 25.50),     
('IoT Home Gateway v2', 3, 4, 89.00),   
('Smart Bulb Multi-color', 2, 2, 15.00),
('Water Leak Detector', 1, 1, 30.00),
('Smart Plug Matter', 2, 3, 45.00),
('Humidity Sensor Plus', 1, 1, 19.99);   

UPDATE DIM_PRODUCTS SET unit_price = 189.99 WHERE product_name = 'Smart Thermostat Pro';

-- Inserts de calendar

/*
 * Utilizo una CTE recursiva para garantizar la integridad de la dimensión temporal, 
 * evitando errores manuales y asegurando que cada hecho en la tabla sells tenga una
 * referencia válida en el calendario (Integridad Referencial).
 */

-- Creacion automática de los 365 días de 2025
INSERT INTO DIM_CALENDAR (calendar_date, day, month, year)
WITH RECURSIVE days(d) AS (
    --Punto de partida (primer día del año)
    SELECT '2025-01-01'
    UNION ALL
    --Sumar un dia en cada iteración hasta llegar a fin de año
    SELECT date(d, '+1 day')
    FROM days
    WHERE d < '2025-12-31'
)
SELECT 
    d AS calendar_date,
    CAST(strftime('%d', d) AS INTEGER) AS day,
    CAST(strftime('%m', d) AS INTEGER) AS month,
    CAST(strftime('%Y', d) AS INTEGER) AS year
FROM days;

-- Inserts de ventas
-- Enero
INSERT INTO FACT_SELLS (sell_date, product_id, client_id, store_id, quantity, total_price)
SELECT '2025-01-15', 1, 1, 3, 2, (2 * 189.99);
-- Febrero
INSERT INTO FACT_SELLS (sell_date, product_id, client_id, store_id, quantity, total_price)
SELECT '2025-02-20', 2, 2, 2, 5, (5 * 25.50);
-- Marzo (Ventas en Tokyo y London)
INSERT INTO FACT_SELLS (sell_date, product_id, client_id, store_id, quantity, total_price)
SELECT '2025-03-10', 3, 3, 4, 1, (1 * 89.00);
INSERT INTO FACT_SELLS (sell_date, product_id, client_id, store_id, quantity, total_price)
SELECT '2025-03-25', 6, 5, 1, 4, (4 * 45.00);
-- Mayo
INSERT INTO FACT_SELLS (sell_date, product_id, client_id, store_id, quantity, total_price)
SELECT '2025-05-05', 4, 4, 5, 10, (10 * 15.00);
-- Agosto
INSERT INTO FACT_SELLS (sell_date, product_id, client_id, store_id, quantity, total_price)
SELECT '2025-08-12', 5, 1, 3, 3, (3 * 30.00);
-- Octubre (Venta grande en Berlin)
INSERT INTO FACT_SELLS (sell_date, product_id, client_id, store_id, quantity, total_price)
SELECT '2025-10-15', 1, 2, 2, 3, (3 * 189.99);

