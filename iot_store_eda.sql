/*
 * Consulta 1: Volumen Total (Metrica Basica)
 */
SELECT 
    strftime('%d/%m/%Y', sell_date) AS formatted_date,
    SUM(quantity) || ' units' AS total_daily_sales
FROM FACT_SELLS
GROUP BY sell_date
ORDER BY sell_date;
-- INSIGHT: Muestra numero de ventas diaria.
-- Para planificar la logistica y el personal de almacen para dias de alta demanda.


/*
 * Consulta 2: El Producto más vendido (Agrupacion)
 */
SELECT 
    p.product_name, 
    SUM(s.quantity) AS units_sold
FROM FACT_SELLS s
JOIN DIM_PRODUCTS p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY units_sold DESC
LIMIT 1;
-- INSIGHT: Muestra el producto con mayor numero de ventas.
-- Bueno para negociar con proveedores y centrar campañas de marketing.

/*
 * Consulta 3: Protocolos más demandados (JOIN)
 */
SELECT 
    pr.protocol_name, 
    COUNT(s.sell_id) AS total_sells
FROM FACT_SELLS s
JOIN DIM_PRODUCTS p ON s.product_id = p.product_id
JOIN DIM_PROTOCOLS pr ON p.protocol_id = pr.protocol_id
GROUP BY pr.protocol_name
ORDER BY total_sells DESC;
-- INSIGHT: Muestra los protocolos más vendidos.
-- Ayuda a ver que tecnologias seguir apoyando.


/*
 * Consulta 4: Clientes "Fantasma" (LEFT JOIN)
 */
SELECT c.client_name, c.email, ci.city_name
FROM DIM_CLIENTS c
LEFT JOIN DIM_CITIES ci ON c.city_id = ci.city_id
WHERE ci.city_name IS NULL;
-- INSIGHT: Muestra los registros de clientes con informacion geografica incompleta.
-- Para la limpieza de datos nulos.


/*
 * Consulta 5: Análisis de Estacionalidad por Trimestre (CASE)
 */
SELECT 
    p.product_name AS Product,
    SUM(CASE WHEN c.quarter = 1 THEN s.quantity ELSE 0 END) AS Q1_Jan_Mar,
    SUM(CASE WHEN c.quarter = 2 THEN s.quantity ELSE 0 END) AS Q2_Apr_Jun,
    SUM(CASE WHEN c.quarter = 3 THEN s.quantity ELSE 0 END) AS Q3_Jul_Sep,
    SUM(CASE WHEN c.quarter = 4 THEN s.quantity ELSE 0 END) AS Q4_Oct_Dec,
    SUM(s.quantity) AS Annual_Total
FROM FACT_SELLS s
JOIN DIM_PRODUCTS p ON s.product_id = p.product_id
JOIN DIM_CALENDAR c ON s.sell_date = c.calendar_date
GROUP BY p.product_name
ORDER BY Annual_Total DESC;
-- Insight: Muestra el volumen de ventas por cada trimestre del año.
-- Ayuda a ver en que trimestre del año cada producto tiene su pico de demanda y saber cuando lanzar prmociones. 


/*
 * Consulta 6: Analisis de Productos por encima del Precio Medio (Subquery)
 */
SELECT 
    p.product_name, 
    p.unit_price,
    SUM(s.quantity) AS total_units_sold,
    ROUND(SUM(s.total_price), 2) AS total_revenue_generated
FROM DIM_PRODUCTS p
JOIN FACT_SELLS s ON p.product_id = s.product_id
WHERE p.unit_price > (SELECT AVG(unit_price) FROM DIM_PRODUCTS)
GROUP BY p.product_id
ORDER BY total_revenue_generated DESC;
-- Insight: Muestra los productos con precio superior a la media con su rendimiento en ventas.
-- Ayuda a ver si la estrategia de producto "Gama Alta" esta funcionando o si el stock caro no genera beneficio.

/*
 * Consulta 7: Tendencia Trimestral de Pedidos
 */
SELECT 
    c.year,
    c.quarter,
    COUNT(s.sell_id) AS total_orders,
    SUM(s.total_price) AS quarterly_revenue
FROM FACT_SELLS s
JOIN DIM_CALENDAR c ON s.sell_date = c.calendar_date
GROUP BY c.year, c.quarter;
-- INSIGHT: Muestra la evolución del negocio por trimestre de cada año.
-- Ayuda a saber si el negocio esta creciendo trimestre tras trimestre.


/*
 * Consulta 8: Ranking Geografico y Cuota de Mercado (Window Function)
 */
WITH GeoSales AS (
    SELECT 
        co.country_name,
        SUM(s.total_price) as total_revenue
    FROM FACT_SELLS s
    JOIN DIM_STORES st ON s.store_id = st.store_id
    JOIN DIM_CITIES ci ON st.city_id = ci.city_id
    JOIN DIM_REGIONS re ON ci.region_id = re.region_id
    JOIN DIM_COUNTRIES co ON re.country_id = co.country_id
    GROUP BY co.country_name
)
SELECT 
    country_name,
    total_revenue,
    ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER(), 2) || '%' as percentage_of_global_sales
FROM GeoSales
ORDER BY total_revenue DESC;
-- INSIGHT: Calcula el peso de cada país en la facturación total.
-- Ayuda en la decision sobre expansion o cierre de mercados.


/*
 * Consulta 9: Gasto Medio por Cliente
 */
SELECT 
    cl.client_name, 
    COUNT(s.sell_id) AS purchase_count,
    ROUND(AVG(s.total_price), 2) AS avg_customer_ticket
FROM FACT_SELLS s
JOIN DIM_CLIENTS cl ON s.client_id = cl.client_id
GROUP BY cl.client_id
HAVING purchase_count > 1
ORDER BY avg_customer_ticket DESC;
-- INSIGHT: Muestra a los clientes recurrentes y cuanto gastan de media.
-- Podria ayudar con campañas para clientes VIP.


/*
 * Consulta 10: Rentabilidad por Categoría 
 */
SELECT 
    cat.category_name,
    SUM(s.quantity) as units_sold,
    SUM(s.total_price) as total_income
FROM FACT_SELLS s
JOIN DIM_PRODUCTS p ON s.product_id = p.product_id
JOIN DIM_CATEGORIES cat ON p.category_id = cat.category_id
GROUP BY cat.category_name
ORDER BY total_income DESC;
-- INSIGHT: Muestra los ingresos totales por categoria de dispositivo.
-- Ayuda con la estrategia de compras del próximo año.


-- Vista resumen
DROP VIEW IF EXISTS VIEW_GLOBAL_PERFORMANCE_SUMMARY;

CREATE VIEW VIEW_GLOBAL_PERFORMANCE_SUMMARY AS
SELECT 
    co.country_name AS Country,
    cat.category_name AS Category,
    COUNT(s.sell_id) AS Sales_Count,
    SUM(s.quantity) AS Total_Units,
    ROUND(SUM(s.total_price), 2) AS Total_Revenue,
    ROUND(AVG(s.total_price), 2) AS Avg_Ticket
FROM FACT_SELLS s
JOIN DIM_STORES st ON s.store_id = st.store_id
JOIN DIM_CITIES ci ON st.city_id = ci.city_id
JOIN DIM_REGIONS re ON ci.region_id = re.region_id
JOIN DIM_COUNTRIES co ON re.country_id = co.country_id
JOIN DIM_PRODUCTS p ON s.product_id = p.product_id
JOIN DIM_CATEGORIES cat ON p.category_id = cat.category_id
GROUP BY co.country_name, cat.category_name;

SELECT * FROM VIEW_GLOBAL_PERFORMANCE_SUMMARY;


/*
 * Vista de busqueda
 * Esta vista une la tabla de hechos con todas las tablas de dimensiones 
 * (Clientes, Productos, Protocolos, Geografía). 
 * Pone en una sola fila toda la historia de una venta.
 * Permite ver que dispositivos compro un usuario, en que fecha y bajo qué tecnología
 */
DROP VIEW IF EXISTS VIEW_CLIENT_SALES_SEARCH;

CREATE VIEW VIEW_CLIENT_SALES_SEARCH AS
SELECT 
    cl.client_name AS Client,
    cl.email AS Contact,
    p.product_name AS Product,
    p.unit_price AS Unit_Price,
    s.quantity AS Quantity,
    s.total_price AS Total_Paid,
    s.sell_date AS Date,
    ci.city_name AS Store_City,
    prot.protocol_name AS Technology
FROM FACT_SELLS s
JOIN DIM_CLIENTS cl ON s.client_id = cl.client_id
JOIN DIM_PRODUCTS p ON s.product_id = p.product_id
JOIN DIM_PROTOCOLS prot ON p.protocol_id = prot.protocol_id
JOIN DIM_STORES st ON s.store_id = st.store_id
JOIN DIM_CITIES ci ON st.city_id = ci.city_id;

-- Ejemplo para ver el historial de compra de un cliente
SELECT * FROM VIEW_CLIENT_SALES_SEARCH WHERE Client = 'Cliente 25'; -- Hay Cliente del 1 al 50

