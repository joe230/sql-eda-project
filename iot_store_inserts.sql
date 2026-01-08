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
DELETE FROM DIM_COUNTRIES WHERE country_name = 'France';

INSERT INTO DIM_REGIONS (region_name, country_id) VALUES 
('Greater London', 1), ('Berlin', 2), ('New York', 3), ('Kanto', 4), ('Catalonia', 5);

INSERT INTO DIM_CITIES (city_name, region_id) VALUES 
('London', 1), ('Berlin', 2), ('New York City', 3), ('Tokyo', 4), ('Barcelona', 5);

UPDATE DIM_CITIES SET city_name = 'NYC' WHERE city_name = 'New York City';

-- Inserts de categorias y protocolos
INSERT INTO DIM_CATEGORIES (category_name) VALUES ('Sensor'), ('Actuador'), ('Hub');
INSERT INTO DIM_PROTOCOLS (protocol_name) VALUES ('Zigbee'), ('WiFi'), ('Matter'), ('Thread');

-- Inserts de tiendas y clientes
INSERT INTO DIM_STORES (city_id) VALUES (1), (2), (3), (4), (5);

-- Generar 50 Clientes
INSERT INTO DIM_CLIENTS (client_name, email, city_id)
WITH RECURSIVE cnt(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM cnt WHERE x < 50)
SELECT 
    'Cliente ' || x, 
    'user' || x || '@example.com',
    CASE WHEN x % 10 = 0 THEN NULL ELSE (ABS(RANDOM() % 5) + 1) END 
FROM cnt;

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
 * Utilizo una CTE recursiva para garantizar la integridad y 
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

-- Inserts de ventas (500 Ventas Aleatorias)
INSERT INTO FACT_SELLS (sell_date, product_id, client_id, store_id, quantity, total_price)
WITH RECURSIVE cnt(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM cnt WHERE x < 500)
SELECT 
    date('2025-01-01', '+' || (ABS(RANDOM() % 364)) || ' days'),
    (ABS(RANDOM() % 7) + 1), -- Productos 1 a 7
    (ABS(RANDOM() % 50) + 1), -- Clientes 1 a 50
    (ABS(RANDOM() % 5) + 1), -- Tiendas 1 a 5
    (ABS(RANDOM() % 5) + 1), -- Cantidad 1 a 5
    0 
FROM cnt;

-- Setear el precio total
UPDATE FACT_SELLS 
SET total_price = quantity * (SELECT unit_price FROM DIM_PRODUCTS WHERE DIM_PRODUCTS.product_id = FACT_SELLS.product_id);
