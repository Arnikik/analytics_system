-- Прокси-сервер для маршрутизации запросов между шардами
-- Аналитика интернет-магазина

-- Подключаем расширения
CREATE EXTENSION IF NOT EXISTS "postgres_fdw";

-- Создаем внешние серверы для каждого шарда
CREATE SERVER users_shard_0 
    FOREIGN DATA WRAPPER postgres_fdw 
    OPTIONS (host 'postgres-users', port '5432', dbname 'analytics_users');

CREATE SERVER users_shard_1 
    FOREIGN DATA WRAPPER postgres_fdw 
    OPTIONS (host 'postgres-users', port '5432', dbname 'analytics_users');

CREATE SERVER orders_shard_0 
    FOREIGN DATA WRAPPER postgres_fdw 
    OPTIONS (host 'postgres-orders', port '5432', dbname 'analytics_orders');

CREATE SERVER orders_shard_1 
    FOREIGN DATA WRAPPER postgres_fdw 
    OPTIONS (host 'postgres-orders', port '5432', dbname 'analytics_orders');

CREATE SERVER analytics_shard_0 
    FOREIGN DATA WRAPPER postgres_fdw 
    OPTIONS (host 'postgres-analytics', port '5432', dbname 'analytics_data');

CREATE SERVER analytics_shard_1 
    FOREIGN DATA WRAPPER postgres_fdw 
    OPTIONS (host 'postgres-analytics', port '5432', dbname 'analytics_data');

-- Создаем пользовательские маппинги
CREATE USER MAPPING FOR admin SERVER users_shard_0 
    OPTIONS (user 'admin', password 'admin');

CREATE USER MAPPING FOR admin SERVER users_shard_1 
    OPTIONS (user 'admin', password 'admin');

CREATE USER MAPPING FOR admin SERVER orders_shard_0 
    OPTIONS (user 'admin', password 'admin');

CREATE USER MAPPING FOR admin SERVER orders_shard_1 
    OPTIONS (user 'admin', password 'admin');

CREATE USER MAPPING FOR admin SERVER analytics_shard_0 
    OPTIONS (user 'admin', password 'admin');

CREATE USER MAPPING FOR admin SERVER analytics_shard_1 
    OPTIONS (user 'admin', password 'admin');

-- Создаем внешние таблицы для пользователей
CREATE FOREIGN TABLE users_shard_0 (
    user_id SERIAL,
    username VARCHAR(50),
    email VARCHAR(100),
    registration_date TIMESTAMP
) SERVER users_shard_0 OPTIONS (schema_name 'public', table_name 'users_shard_0');

CREATE FOREIGN TABLE users_shard_1 (
    user_id SERIAL,
    username VARCHAR(50),
    email VARCHAR(100),
    registration_date TIMESTAMP
) SERVER users_shard_1 OPTIONS (schema_name 'public', table_name 'users_shard_1');

-- Создаем внешние таблицы для заказов
CREATE FOREIGN TABLE orders_shard_0 (
    order_id SERIAL,
    user_id INT,
    order_date TIMESTAMP,
    total_amount NUMERIC(10, 2),
    status VARCHAR(20)
) SERVER orders_shard_0 OPTIONS (schema_name 'public', table_name 'orders_shard_0');

CREATE FOREIGN TABLE orders_shard_1 (
    order_id SERIAL,
    user_id INT,
    order_date TIMESTAMP,
    total_amount NUMERIC(10, 2),
    status VARCHAR(20)
) SERVER orders_shard_1 OPTIONS (schema_name 'public', table_name 'orders_shard_1');

-- Создаем внешние таблицы для аналитики
CREATE FOREIGN TABLE product_views_shard_0 (
    view_id SERIAL,
    user_id INT,
    product_id INT,
    product_name VARCHAR(200),
    category VARCHAR(100),
    brand VARCHAR(100),
    view_time TIMESTAMP,
    session_id UUID
) SERVER analytics_shard_0 OPTIONS (schema_name 'public', table_name 'product_views_shard_0');

CREATE FOREIGN TABLE product_views_shard_1 (
    view_id SERIAL,
    user_id INT,
    product_id INT,
    product_name VARCHAR(200),
    category VARCHAR(100),
    brand VARCHAR(100),
    view_time TIMESTAMP,
    session_id UUID
) SERVER analytics_shard_1 OPTIONS (schema_name 'public', table_name 'product_views_shard_1');

-- Создаем представления для объединения данных
CREATE VIEW users AS
    SELECT * FROM users_shard_0
    UNION ALL
    SELECT * FROM users_shard_1;

CREATE VIEW orders AS
    SELECT * FROM orders_shard_0
    UNION ALL
    SELECT * FROM orders_shard_1;

CREATE VIEW product_views AS
    SELECT * FROM product_views_shard_0
    UNION ALL
    SELECT * FROM product_views_shard_1;

-- Создаем функции для маршрутизации
CREATE OR REPLACE FUNCTION get_user_shard(p_user_id INT)
RETURNS TEXT AS $$
BEGIN
    IF p_user_id % 2 = 0 THEN
        RETURN 'users_shard_0';
    ELSE
        RETURN 'users_shard_1';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_order_shard(p_user_id INT)
RETURNS TEXT AS $$
BEGIN
    IF p_user_id % 2 = 0 THEN
        RETURN 'orders_shard_0';
    ELSE
        RETURN 'orders_shard_1';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_analytics_shard(p_user_id INT)
RETURNS TEXT AS $$
BEGIN
    IF p_user_id % 2 = 0 THEN
        RETURN 'analytics_shard_0';
    ELSE
        RETURN 'analytics_shard_1';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Функции для триггеров маршрутизации
CREATE OR REPLACE FUNCTION route_user_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id % 2 = 0 THEN
        INSERT INTO users_shard_0 VALUES (NEW.*);
    ELSE
        INSERT INTO users_shard_1 VALUES (NEW.*);
    END IF;
    RETURN NULL; -- Important: return NULL to prevent duplicate insertion
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION route_order_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id % 2 = 0 THEN
        INSERT INTO orders_shard_0 (user_id, order_date, total_amount, status)
        VALUES (NEW.user_id, NEW.order_date, NEW.total_amount, NEW.status);
    ELSE
        INSERT INTO orders_shard_1 (user_id, order_date, total_amount, status)
        VALUES (NEW.user_id, NEW.order_date, NEW.total_amount, NEW.status);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION route_analytics_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id % 2 = 0 THEN
        INSERT INTO product_views_shard_0 (user_id, product_id, product_name, category, brand)
        VALUES (NEW.user_id, NEW.product_id, NEW.product_name, NEW.category, NEW.brand);
    ELSE
        INSERT INTO product_views_shard_1 (user_id, product_id, product_name, category, brand)
        VALUES (NEW.user_id, NEW.product_id, NEW.product_name, NEW.category, NEW.brand);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION route_order_items_insert()
RETURNS TRIGGER AS $$
DECLARE
    order_user_id INT;
BEGIN
    -- We need to find the user_id from the orders table to route correctly
    SELECT user_id INTO order_user_id FROM orders WHERE order_id = NEW.order_id LIMIT 1;
    IF order_user_id % 2 = 0 THEN
        INSERT INTO order_items_shard_0 VALUES (NEW.*);
    ELSE
        INSERT INTO order_items_shard_1 VALUES (NEW.*);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION route_search_history_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO search_history_table (user_id, query_text, search_time, results_count)
    VALUES (NEW.user_id, NEW.query_text, NEW.search_time, NEW.results_count);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Теперь триггеры (после функций)
DROP TRIGGER IF EXISTS users_insert_trigger ON users;
CREATE TRIGGER users_insert_trigger
    INSTEAD OF INSERT ON users
    FOR EACH ROW EXECUTE FUNCTION route_user_insert();

DROP TRIGGER IF EXISTS orders_insert_trigger ON orders;
CREATE TRIGGER orders_insert_trigger
    INSTEAD OF INSERT ON orders
    FOR EACH ROW EXECUTE FUNCTION route_order_insert();

DROP TRIGGER IF EXISTS analytics_insert_trigger ON product_views;
CREATE TRIGGER analytics_insert_trigger
    INSTEAD OF INSERT ON product_views
    FOR EACH ROW EXECUTE FUNCTION route_analytics_insert();

-- =================================================================
-- FOREIGN TABLES, VIEWS, and TRIGGERS for complex cases
-- =================================================================

-- Order Items (Sharded)
-- 1. Create Foreign Tables
CREATE FOREIGN TABLE order_items_shard_0 (
    item_id SERIAL,
    order_id INT,
    product_id INT,
    product_name VARCHAR(200),
    quantity INT,
    unit_price NUMERIC(10, 2),
    total_price NUMERIC(10, 2),
    category VARCHAR(100),
    brand VARCHAR(100)
) SERVER orders_shard_0 OPTIONS (schema_name 'public', table_name 'order_items_shard_0');

CREATE FOREIGN TABLE order_items_shard_1 (
    item_id SERIAL,
    order_id INT,
    product_id INT,
    product_name VARCHAR(200),
    quantity INT,
    unit_price NUMERIC(10, 2),
    total_price NUMERIC(10, 2),
    category VARCHAR(100),
    brand VARCHAR(100)
) SERVER orders_shard_1 OPTIONS (schema_name 'public', table_name 'order_items_shard_1');

-- 2. Create View
CREATE OR REPLACE VIEW order_items AS
    SELECT * FROM order_items_shard_0
    UNION ALL
    SELECT * FROM order_items_shard_1;

-- 3. Create Trigger
DROP TRIGGER IF EXISTS order_items_insert_trigger ON order_items;
CREATE TRIGGER order_items_insert_trigger
    INSTEAD OF INSERT ON order_items
    FOR EACH ROW EXECUTE FUNCTION route_order_items_insert();


-- Search History (Not sharded, but needs a VIEW and TRIGGER)
-- 1. Create Foreign Table
CREATE FOREIGN TABLE search_history_table (
    search_id SERIAL,
    user_id INT,
    query_text TEXT,
    search_time TIMESTAMP,
    results_count INT
) SERVER analytics_shard_0 OPTIONS (schema_name 'public', table_name 'search_history');

-- 2. Create View
CREATE OR REPLACE VIEW search_history AS
      SELECT * FROM search_history_table;

-- 3. Create Trigger
DROP TRIGGER IF EXISTS search_history_insert_trigger ON search_history;
CREATE TRIGGER search_history_insert_trigger
    INSTEAD OF INSERT ON search_history
    FOR EACH ROW EXECUTE FUNCTION route_search_history_insert();