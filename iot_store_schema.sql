PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS FACT_SELLS;
DROP TABLE IF EXISTS DIM_CALENDAR;
DROP TABLE IF EXISTS DIM_PRODUCTS;
DROP TABLE IF EXISTS DIM_CLIENTS;
DROP TABLE IF EXISTS DIM_STORES;
DROP TABLE IF EXISTS DIM_COUNTRIES;
DROP TABLE IF EXISTS DIM_REGIONS;
DROP TABLE IF EXISTS DIM_CITIES;
DROP TABLE IF EXISTS DIM_CATEGORIES;
DROP TABLE IF EXISTS DIM_PROTOCOLS;

/*
 * He implementado una jerarquia geografica senzilla (Pais > Region > Ciudad). 
 * Así podemos ver la facturacion total de un pais, region o ciudad. 
 * Tambien garantizamos que los nombres geograficos siempre sean los mismos.
 */

CREATE TABLE IF NOT EXISTS DIM_COUNTRIES (
    country_id INTEGER PRIMARY KEY,
    country_name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS DIM_REGIONS (
    region_id INTEGER PRIMARY KEY,
    region_name TEXT NOT NULL,
    country_id INTEGER NOT NULL,
    FOREIGN KEY (country_id) REFERENCES DIM_COUNTRIES(country_id)
);

CREATE TABLE IF NOT EXISTS DIM_CITIES (
    city_id INTEGER PRIMARY KEY,
    city_name TEXT NOT NULL,
    region_id INTEGER NOT NULL,
    FOREIGN KEY (region_id) REFERENCES DIM_REGIONS(region_id)
);

/*
 * He decidido normalizar las categorías y protocolos en tablas independientes 
 * para asegurar que no haya problemas con nombres mal escritos o que falte alguno por poner (integridad referencial) 
 * y facilitar la escalabilidad del catálogo de productos IoT. 
 * Tambien permite actualizaciones globales de los protocolos y categorias sin afectar a la tabla de productos.
 */

-- Tabla de categorias de producto
CREATE TABLE IF NOT EXISTS DIM_CATEGORIES (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL UNIQUE
);

-- Tabla de protocolos de dispositivos IoT
CREATE TABLE IF NOT EXISTS DIM_PROTOCOLS (
    protocol_id INTEGER PRIMARY KEY,
    protocol_name TEXT NOT NULL UNIQUE
);

-- Tabla de productos IoT
CREATE TABLE IF NOT EXISTS DIM_PRODUCTS (
	product_id INTEGER PRIMARY KEY,
	product_name TEXT NOT NULL,
	category_id INTEGER NOT NULL,
	protocol_id INTEGER NOT NULL,
	unit_price REAL NOT NULL,
	
	-- Claves foraneas con relacion 1:N a las tablas de protocolos y categorias
	FOREIGN KEY (category_id) REFERENCES DIM_CATEGORIES(category_id),
	FOREIGN KEY (protocol_id) REFERENCES DIM_PROTOCOLS(protocol_id),
	
	-- Constraint para verificar que el precio del producto sea positivo
	CONSTRAINT chk_unit_price_positive CHECK (unit_price > 0)
);

-- Tabla de clientes
CREATE TABLE IF NOT EXISTS DIM_CLIENTS (
	client_id INTEGER PRIMARY KEY,
	client_name TEXT NOT NULL,
	email TEXT UNIQUE,
	city_id INTEGER,
	
	FOREIGN KEY (city_id) REFERENCES DIM_CITIES(city_id)
);

-- Tabla de tiendas
CREATE TABLE IF NOT EXISTS DIM_STORES (
	store_id INTEGER PRIMARY KEY,
	city_id INTEGER NOT NULL,
	
	FOREIGN KEY (city_id) REFERENCES DIM_CITIES(city_id)
);

/*
 * Tabla de calendario
 * El trimestre se genera automaticamente dependiendo del mes del año 
 */
CREATE TABLE IF NOT EXISTS DIM_CALENDAR (
	calendar_date DATE PRIMARY KEY,
	day INTEGER NOT NULL,
	month INTEGER NOT NULL,
	year INTEGER NOT NULL,
	quarter INTEGER GENERATED ALWAYS AS (
		CASE 
			WHEN month <= 3 THEN 1 
			WHEN month <= 6 THEN 2 
			WHEN month <= 9 THEN 3 
			ELSE 4 
		END
	) STORED
);

-- Tabla de ventas
CREATE TABLE IF NOT EXISTS FACT_SELLS (
	sell_id INTEGER PRIMARY KEY,
	sell_date DATE NOT NULL,
	product_id INTEGER NOT NULL,
	client_id INTEGER NOT NULL,
	store_id INTEGER NOT NULL,
	quantity INTEGER NOT NULL,
	total_price REAL NOT NULL,
	
	-- Claves foraneas con relacion 1:N a las tablas de calendario, productos, clientes y tiendas
	FOREIGN KEY (sell_date) REFERENCES DIM_CALENDAR(calendar_date),
    FOREIGN KEY (product_id) REFERENCES DIM_PRODUCTS(product_id),
    FOREIGN KEY (client_id) REFERENCES DIM_CLIENTS(client_id),
    FOREIGN KEY (store_id) REFERENCES DIM_STORES(store_id),
    
    -- Constraint para verificar que la cantidad de ventas de un producto sea positivo
    CONSTRAINT chk_quantity_positive CHECK (quantity > 0)
);

-- Indice para optimizar consultas
-- Lo hago en sell_date por ser la columna que posiblemente más se usara
CREATE INDEX IF NOT EXISTS idx_sales_date ON FACT_SELLS(sell_date);