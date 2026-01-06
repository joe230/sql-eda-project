-- Numero de ventas
SELECT COUNT(DISTINCT sell_id) FROM FACT_SELLS;

-- Mostrar el numero de ventas por dia
SELECT 
    strftime('%d/%m/%Y', sell_date) AS formatted_date,
    SUM(quantity) || ' units' AS total_daily_sales
FROM FACT_SELLS
GROUP BY sell_date
ORDER BY sell_date;

-- Mostrar el producto con mayor numero de ventas
SELECT 
    p.product_name, 
    SUM(s.quantity) AS units_sold
FROM FACT_SELLS s
JOIN DIM_PRODUCTS p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY units_sold DESC
LIMIT 1;

-- Mostrar el protocolo mas demandado
SELECT 
    pr.protocol_name, 
    COUNT(s.sell_id) AS total_uses
FROM FACT_SELLS s
JOIN DIM_PRODUCTS p ON s.product_id = p.product_id
JOIN DIM_PROTOCOLS pr ON p.protocol_id = pr.protocol_id
GROUP BY pr.protocol_name
ORDER BY total_uses DESC;

-- Mostrar las categorias mas demandadas
SELECT 
	cat.category_name,
	COUNT(s.sell_id) AS total_uses
FROM FACT_SELLS s
JOIN DIM_PRODUCTS p ON s.product_id = p.product_id 
JOIN DIM_CATEGORIES cat ON p.category_id = cat.category_id 
GROUP BY cat.category_name 
ORDER BY total_uses DESC;

-- Ranking de Paises/Ciudades por facturacion
WITH GeoSales AS (
    SELECT 
        co.country_name,
        ci.city_name,
        SUM(s.total_price) as total_city_revenue
    FROM FACT_SELLS s
    JOIN DIM_STORES st ON s.store_id = st.store_id
    JOIN DIM_CITIES ci ON st.city_id = ci.city_id
    JOIN DIM_REGIONS re ON ci.region_id = re.region_id
    JOIN DIM_COUNTRIES co ON re.country_id = co.country_id
    GROUP BY co.country_name, ci.city_name
)
SELECT 
    country_name,
    city_name,
    total_city_revenue,
    -- Calcula el % que representa cada ciudad sobre el total global
    ROUND(total_city_revenue * 100.0 / SUM(total_city_revenue) OVER(), 2) || '%' as percentage_of_sales
FROM GeoSales
ORDER BY total_city_revenue DESC;


-- Tendencia Trimestral Global
SELECT 
    c.year,
    c.quarter,
    COUNT(s.sell_id) as total_pedidos,
    SUM(s.total_price) as ingresos_trimestre,
    -- Media de ingresos por pedido en el trimestre
    ROUND(AVG(s.total_price), 2) as ticket_medio
FROM FACT_SELLS s
JOIN DIM_CALENDAR c ON s.sell_date = c.calendar_date
GROUP BY c.year, c.quarter
ORDER BY c.year, c.quarter;


-- Vista resumen
DROP VIEW IF EXISTS VIEW_GLOBAL_PERFORMANCE_SUMMARY;

CREATE VIEW VIEW_GLOBAL_PERFORMANCE_SUMMARY AS
SELECT 
    co.country_name AS Pais,
    cat.category_name AS Categoria,
    COUNT(s.sell_id) AS Num_Ventas,
    SUM(s.quantity) AS Unidades_Totales,
    ROUND(SUM(s.total_price), 2) AS Ingresos_Totales,
    ROUND(AVG(s.total_price), 2) AS Ticket_Medio
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
    cl.client_name AS Cliente,
    cl.email AS Contacto,
    p.product_name AS Producto,
    p.unit_price AS Precio_Unitario,
    s.quantity AS Cantidad,
    s.total_price AS Total_Pagado,
    s.sell_date AS Fecha,
    ci.city_name AS Ciudad_Tienda,
    prot.protocol_name AS Tecnologia
FROM FACT_SELLS s
JOIN DIM_CLIENTS cl ON s.client_id = cl.client_id
JOIN DIM_PRODUCTS p ON s.product_id = p.product_id
JOIN DIM_PROTOCOLS prot ON p.protocol_id = prot.protocol_id
JOIN DIM_STORES st ON s.store_id = st.store_id
JOIN DIM_CITIES ci ON st.city_id = ci.city_id;

-- Ejemplo para ver el historial de compra de un cliente
SELECT * FROM VIEW_CLIENT_SALES_SEARCH WHERE Cliente = 'Alice Smith';