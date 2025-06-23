-- ANALYTICS DOMAIN - Аналитика интернет-магазина
-- Шардирование по user_id:
-- user_id % 2 = 0 → shard_0
-- user_id % 2 = 1 → shard_1

-- Подключаем расширения
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Таблицы просмотров товаров (шардированные)
CREATE TABLE product_views_shard_0 (
    view_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    product_name VARCHAR(200),
    category VARCHAR(100),
    brand VARCHAR(100),
    view_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id UUID DEFAULT gen_random_uuid(),
    page_url TEXT,
    referrer_url TEXT,
    time_on_page INTEGER, -- в секундах
    device_type VARCHAR(50), -- 'desktop', 'mobile', 'tablet'
    browser VARCHAR(50),
    ip_address INET
);

CREATE TABLE product_views_shard_1 (
    view_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    product_name VARCHAR(200),
    category VARCHAR(100),
    brand VARCHAR(100),
    view_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id UUID DEFAULT gen_random_uuid(),
    page_url TEXT,
    referrer_url TEXT,
    time_on_page INTEGER,
    device_type VARCHAR(50),
    browser VARCHAR(50),
    ip_address INET
);

-- Таблицы кликов (шардированные)
CREATE TABLE click_logs_shard_0 (
    click_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    element_type VARCHAR(50), -- 'banner', 'button', 'link', 'product_card'
    element_id VARCHAR(50),
    element_text VARCHAR(200),
    click_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id UUID DEFAULT gen_random_uuid(),
    page_url TEXT,
    coordinates_x INTEGER,
    coordinates_y INTEGER,
    device_type VARCHAR(50),
    browser VARCHAR(50)
);

CREATE TABLE click_logs_shard_1 (
    click_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    element_type VARCHAR(50),
    element_id VARCHAR(50),
    element_text VARCHAR(200),
    click_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id UUID DEFAULT gen_random_uuid(),
    page_url TEXT,
    coordinates_x INTEGER,
    coordinates_y INTEGER,
    device_type VARCHAR(50),
    browser VARCHAR(50)
);

-- История поиска (без шардинга)
CREATE TABLE search_history (
    search_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    query_text TEXT,
    search_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    results_count INTEGER,
    session_id UUID DEFAULT gen_random_uuid(),
    device_type VARCHAR(50),
    browser VARCHAR(50),
    filters_applied JSONB -- JSON с примененными фильтрами
);

-- Корзина покупок (шардированная)
CREATE TABLE cart_items_shard_0 (
    cart_item_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    product_name VARCHAR(200),
    quantity INT DEFAULT 1,
    added_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    removed_time TIMESTAMP,
    session_id UUID DEFAULT gen_random_uuid(),
    price_at_add NUMERIC(10, 2)
);

CREATE TABLE cart_items_shard_1 (
    cart_item_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    product_name VARCHAR(200),
    quantity INT DEFAULT 1,
    added_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    removed_time TIMESTAMP,
    session_id UUID DEFAULT gen_random_uuid(),
    price_at_add NUMERIC(10, 2)
);

-- Избранное (шардированное)
CREATE TABLE wishlist_items_shard_0 (
    wishlist_item_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    product_name VARCHAR(200),
    added_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    removed_time TIMESTAMP,
    category VARCHAR(100),
    brand VARCHAR(100)
);

CREATE TABLE wishlist_items_shard_1 (
    wishlist_item_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    product_name VARCHAR(200),
    added_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    removed_time TIMESTAMP,
    category VARCHAR(100),
    brand VARCHAR(100)
);

-- Отзывы и рейтинги (без шардинга)
CREATE TABLE product_reviews (
    review_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    product_name VARCHAR(200),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    helpful_votes INTEGER DEFAULT 0,
    verified_purchase BOOLEAN DEFAULT FALSE
);

-- События пользователей (шардированные)
CREATE TABLE user_events_shard_0 (
    event_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    event_type VARCHAR(50), -- 'login', 'logout', 'registration', 'password_reset'
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id UUID DEFAULT gen_random_uuid(),
    device_type VARCHAR(50),
    browser VARCHAR(50),
    ip_address INET,
    user_agent TEXT,
    metadata JSONB -- дополнительные данные события
);

CREATE TABLE user_events_shard_1 (
    event_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    event_type VARCHAR(50),
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id UUID DEFAULT gen_random_uuid(),
    device_type VARCHAR(50),
    browser VARCHAR(50),
    ip_address INET,
    user_agent TEXT,
    metadata JSONB
);

-- Индексы для оптимизации запросов
CREATE INDEX idx_views_shard_0_user_id ON product_views_shard_0(user_id);
CREATE INDEX idx_views_shard_1_user_id ON product_views_shard_1(user_id);
CREATE INDEX idx_views_shard_0_product_id ON product_views_shard_0(product_id);
CREATE INDEX idx_views_shard_1_product_id ON product_views_shard_1(product_id);
CREATE INDEX idx_views_shard_0_time ON product_views_shard_0(view_time);
CREATE INDEX idx_views_shard_1_time ON product_views_shard_1(view_time);
CREATE INDEX idx_views_shard_0_category ON product_views_shard_0(category);
CREATE INDEX idx_views_shard_1_category ON product_views_shard_1(category);

CREATE INDEX idx_clicks_shard_0_user_id ON click_logs_shard_0(user_id);
CREATE INDEX idx_clicks_shard_1_user_id ON click_logs_shard_1(user_id);
CREATE INDEX idx_clicks_shard_0_time ON click_logs_shard_0(click_time);
CREATE INDEX idx_clicks_shard_1_time ON click_logs_shard_1(click_time);
CREATE INDEX idx_clicks_shard_0_type ON click_logs_shard_0(element_type);
CREATE INDEX idx_clicks_shard_1_type ON click_logs_shard_1(element_type);

CREATE INDEX idx_search_user_id ON search_history(user_id);
CREATE INDEX idx_search_time ON search_history(search_time);
CREATE INDEX idx_search_query ON search_history USING gin(to_tsvector('russian', query_text));

CREATE INDEX idx_cart_shard_0_user_id ON cart_items_shard_0(user_id);
CREATE INDEX idx_cart_shard_1_user_id ON cart_items_shard_1(user_id);
CREATE INDEX idx_cart_shard_0_added ON cart_items_shard_0(added_time);
CREATE INDEX idx_cart_shard_1_added ON cart_items_shard_1(added_time);

CREATE INDEX idx_wishlist_shard_0_user_id ON wishlist_items_shard_0(user_id);
CREATE INDEX idx_wishlist_shard_1_user_id ON wishlist_items_shard_1(user_id);
CREATE INDEX idx_wishlist_shard_0_added ON wishlist_items_shard_0(added_time);
CREATE INDEX idx_wishlist_shard_1_added ON wishlist_items_shard_1(added_time);

CREATE INDEX idx_reviews_user_id ON product_reviews(user_id);
CREATE INDEX idx_reviews_product_id ON product_reviews(product_id);
CREATE INDEX idx_reviews_rating ON product_reviews(rating);
CREATE INDEX idx_reviews_date ON product_reviews(review_date);

CREATE INDEX idx_events_shard_0_user_id ON user_events_shard_0(user_id);
CREATE INDEX idx_events_shard_1_user_id ON user_events_shard_1(user_id);
CREATE INDEX idx_events_shard_0_time ON user_events_shard_0(event_time);
CREATE INDEX idx_events_shard_1_time ON user_events_shard_1(event_time);
CREATE INDEX idx_events_shard_0_type ON user_events_shard_0(event_type);
CREATE INDEX idx_events_shard_1_type ON user_events_shard_1(event_type);

-- Защита от ручной вставки search_id
CREATE OR REPLACE FUNCTION prevent_manual_search_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.search_id IS NOT NULL THEN
        RAISE EXCEPTION 'Вставка с явным search_id запрещена. Используйте автоинкремент.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS prevent_manual_search_id_trigger ON search_history;
CREATE TRIGGER prevent_manual_search_id_trigger
BEFORE INSERT ON search_history
FOR EACH ROW EXECUTE FUNCTION prevent_manual_search_id();

-- Тестовые данные
-- Просмотры товаров для shard_0
INSERT INTO product_views_shard_0 (user_id, product_id, product_name, category, brand, view_time, page_url, referrer_url, time_on_page, device_type, browser, ip_address) VALUES
(2, 101, 'iPhone 15 Pro Max 256GB', 'Smartphones', 'Apple', '2024-03-01 14:30:00', '/product/101', '/category/smartphones', 120, 'desktop', 'Chrome', '192.168.1.100'),
(2, 102, 'AirPods Pro 2', 'Audio', 'Apple', '2024-03-01 14:35:00', '/product/102', '/product/101', 45, 'desktop', 'Chrome', '192.168.1.100'),
(4, 103, 'MacBook Air M2 13"', 'Laptops', 'Apple', '2024-03-01 16:45:00', '/product/103', '/category/laptops', 180, 'mobile', 'Safari', '192.168.1.101'),
(6, 105, 'Samsung Galaxy S24 Ultra', 'Smartphones', 'Samsung', '2024-03-01 09:15:00', '/product/105', '/search?q=samsung', 90, 'tablet', 'Chrome', '192.168.1.102'),
(8, 107, 'Dell XPS 13', 'Laptops', 'Dell', '2024-03-01 12:20:00', '/product/107', '/category/laptops', 150, 'desktop', 'Edge', '192.168.1.103');

-- Просмотры товаров для shard_1
INSERT INTO product_views_shard_1 (user_id, product_id, product_name, category, brand, view_time, page_url, referrer_url, time_on_page, device_type, browser, ip_address) VALUES
(1, 201, 'iPad Pro 12.9" M2', 'Tablets', 'Apple', '2024-03-01 10:00:00', '/product/201', '/category/tablets', 200, 'desktop', 'Firefox', '192.168.1.104'),
(3, 202, 'Sony A7 IV Camera', 'Cameras', 'Sony', '2024-03-01 15:30:00', '/product/202', '/search?q=camera', 300, 'mobile', 'Chrome', '192.168.1.105'),
(5, 204, 'Logitech MX Master 3S', 'Accessories', 'Logitech', '2024-03-01 11:45:00', '/product/204', '/category/accessories', 60, 'desktop', 'Edge', '192.168.1.106'),
(7, 205, 'LG OLED C3 65"', 'TVs', 'LG', '2024-03-01 13:20:00', '/product/205', '/category/tvs', 240, 'mobile', 'Safari', '192.168.1.107'),
(9, 207, 'Nike Air Max 270', 'Shoes', 'Nike', '2024-03-01 17:10:00', '/product/207', '/search?q=nike', 75, 'desktop', 'Chrome', '192.168.1.108');

-- Клики для shard_0
INSERT INTO click_logs_shard_0 (user_id, element_type, element_id, element_text, click_time, page_url, coordinates_x, coordinates_y, device_type, browser) VALUES
(2, 'button', 'add_to_cart', 'Добавить в корзину', '2024-03-01 14:32:00', '/product/101', 450, 600, 'desktop', 'Chrome'),
(2, 'link', 'product_reviews', 'Отзывы (15)', '2024-03-01 14:33:00', '/product/101', 200, 800, 'desktop', 'Chrome'),
(4, 'banner', 'spring_sale', 'Весенняя распродажа -30%', '2024-03-01 16:47:00', '/home', 300, 150, 'mobile', 'Safari'),
(6, 'button', 'buy_now', 'Купить сейчас', '2024-03-01 09:17:00', '/product/105', 500, 700, 'tablet', 'Chrome'),
(8, 'link', 'product_specs', 'Характеристики', '2024-03-01 12:22:00', '/product/107', 350, 500, 'desktop', 'Edge');

-- Клики для shard_1
INSERT INTO click_logs_shard_1 (user_id, element_type, element_id, element_text, click_time, page_url, coordinates_x, coordinates_y, device_type, browser) VALUES
(1, 'button', 'add_to_wishlist', 'В избранное', '2024-03-01 10:02:00', '/product/201', 400, 550, 'desktop', 'Firefox'),
(3, 'link', 'product_video', 'Смотреть видео', '2024-03-01 15:32:00', '/product/202', 250, 400, 'mobile', 'Chrome'),
(5, 'button', 'add_to_cart', 'Добавить в корзину', '2024-03-01 11:47:00', '/product/204', 480, 650, 'desktop', 'Edge'),
(7, 'banner', 'new_arrivals', 'Новые поступления', '2024-03-01 13:22:00', '/home', 200, 100, 'mobile', 'Safari'),
(9, 'link', 'size_guide', 'Таблица размеров', '2024-03-01 17:12:00', '/product/207', 300, 750, 'desktop', 'Chrome');

-- История поиска
INSERT INTO search_history (user_id, query_text, search_time, results_count, device_type, browser, filters_applied) VALUES
(1, 'iphone 15 pro max', '2024-03-01 09:30:00', 5, 'desktop', 'Firefox', '{"brand": "Apple", "price_min": 100000}'),
(2, 'ноутбуки для работы', '2024-03-01 14:00:00', 12, 'desktop', 'Chrome', '{"category": "Laptops", "price_max": 200000}'),
(3, 'камера sony', '2024-03-01 15:00:00', 8, 'mobile', 'Chrome', '{"brand": "Sony"}'),
(4, 'беспроводные наушники', '2024-03-01 16:30:00', 15, 'mobile', 'Safari', '{"category": "Audio", "wireless": true}'),
(5, 'игровая мышь', '2024-03-01 11:30:00', 10, 'desktop', 'Edge', '{"category": "Accessories", "gaming": true}'),
(6, 'samsung galaxy', '2024-03-01 09:00:00', 7, 'tablet', 'Chrome', '{"brand": "Samsung"}'),
(7, 'телевизор 4k', '2024-03-01 13:00:00', 6, 'mobile', 'Safari', '{"category": "TVs", "resolution": "4K"}'),
(8, 'dell xps', '2024-03-01 12:00:00', 3, 'desktop', 'Edge', '{"brand": "Dell"}'),
(9, 'кроссовки nike', '2024-03-01 17:00:00', 20, 'desktop', 'Chrome', '{"brand": "Nike", "category": "Shoes"}'),
(10, 'airpods pro', '2024-03-01 18:00:00', 4, 'mobile', 'Safari', '{"brand": "Apple", "category": "Audio"}');

-- Корзина для shard_0
INSERT INTO cart_items_shard_0 (user_id, product_id, product_name, quantity, added_time, price_at_add) VALUES
(2, 101, 'iPhone 15 Pro Max 256GB', 1, '2024-03-01 14:32:00', 120000.00),
(2, 102, 'AirPods Pro 2', 1, '2024-03-01 14:35:00', 25000.00),
(4, 103, 'MacBook Air M2 13"', 1, '2024-03-01 16:47:00', 150000.00),
(6, 105, 'Samsung Galaxy S24 Ultra', 1, '2024-03-01 09:17:00', 140000.00),
(8, 107, 'Dell XPS 13', 1, '2024-03-01 12:22:00', 120000.00);

-- Корзина для shard_1
INSERT INTO cart_items_shard_1 (user_id, product_id, product_name, quantity, added_time, price_at_add) VALUES
(1, 201, 'iPad Pro 12.9" M2', 1, '2024-03-01 10:02:00', 180000.00),
(3, 202, 'Sony A7 IV Camera', 1, '2024-03-01 15:32:00', 250000.00),
(5, 204, 'Logitech MX Master 3S', 1, '2024-03-01 11:47:00', 12000.00),
(7, 205, 'LG OLED C3 65"', 1, '2024-03-01 13:22:00', 180000.00),
(9, 207, 'Nike Air Max 270', 1, '2024-03-01 17:12:00', 15000.00);

-- Избранное для shard_0
INSERT INTO wishlist_items_shard_0 (user_id, product_id, product_name, added_time, category, brand) VALUES
(2, 108, 'Sony WH-1000XM5', '2024-03-01 14:40:00', 'Audio', 'Sony'),
(4, 104, 'Magic Mouse', '2024-03-01 16:50:00', 'Accessories', 'Apple'),
(6, 106, 'Galaxy Buds Pro', '2024-03-01 09:20:00', 'Audio', 'Samsung'),
(8, 108, 'Sony WH-1000XM5', '2024-03-01 12:25:00', 'Audio', 'Sony'),
(10, 101, 'iPhone 15 Pro Max 256GB', '2024-03-01 18:35:00', 'Smartphones', 'Apple');

-- Избранное для shard_1
INSERT INTO wishlist_items_shard_1 (user_id, product_id, product_name, added_time, category, brand) VALUES
(1, 203, 'Sony 24-70mm Lens', '2024-03-01 10:05:00', 'Lenses', 'Sony'),
(3, 206, 'Samsung Soundbar Q990C', '2024-03-01 15:35:00', 'Audio', 'Samsung'),
(5, 201, 'iPad Pro 12.9" M2', '2024-03-01 11:50:00', 'Tablets', 'Apple'),
(7, 202, 'Sony A7 IV Camera', '2024-03-01 13:25:00', 'Cameras', 'Sony'),
(9, 204, 'Logitech MX Master 3S', '2024-03-01 17:15:00', 'Accessories', 'Logitech');

-- Отзывы
INSERT INTO product_reviews (user_id, product_id, product_name, rating, review_text, review_date, helpful_votes, verified_purchase) VALUES
(1, 201, 'iPad Pro 12.9" M2', 5, 'Отличный планшет! Дисплей потрясающий, производительность на высоте.', '2024-02-28 16:30:00', 12, TRUE),
(2, 101, 'iPhone 15 Pro Max 256GB', 4, 'Хороший телефон, но дорогой. Камера отличная.', '2024-02-25 14:20:00', 8, TRUE),
(3, 202, 'Sony A7 IV Camera', 5, 'Профессиональная камера, качество фото превосходное!', '2024-02-20 11:15:00', 25, TRUE),
(4, 103, 'MacBook Air M2 13"', 5, 'Лучший ноутбук для работы! Батарея держит долго.', '2024-02-18 09:45:00', 15, TRUE),
(5, 204, 'Logitech MX Master 3S', 4, 'Удобная мышь, но кнопки немного шумные.', '2024-02-15 13:10:00', 6, TRUE);

-- События пользователей для shard_0
INSERT INTO user_events_shard_0 (user_id, event_type, event_time, device_type, browser, ip_address, user_agent, metadata) VALUES
(2, 'login', '2024-03-01 14:25:00', 'desktop', 'Chrome', '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '{"login_method": "email"}'),
(4, 'login', '2024-03-01 16:40:00', 'mobile', 'Safari', '192.168.1.101', 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)', '{"login_method": "social"}'),
(6, 'registration', '2024-03-01 09:10:00', 'tablet', 'Chrome', '192.168.1.102', 'Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X)', '{"registration_source": "web"}'),
(8, 'password_reset', '2024-03-01 12:15:00', 'desktop', 'Edge', '192.168.1.103', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '{"reset_method": "email"}'),
(10, 'logout', '2024-03-01 18:40:00', 'mobile', 'Safari', '192.168.1.104', 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)', '{"session_duration": 3600}');

-- События пользователей для shard_1
INSERT INTO user_events_shard_1 (user_id, event_type, event_time, device_type, browser, ip_address, user_agent, metadata) VALUES
(1, 'login', '2024-03-01 09:55:00', 'desktop', 'Firefox', '192.168.1.105', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0)', '{"login_method": "email"}'),
(3, 'login', '2024-03-01 15:25:00', 'mobile', 'Chrome', '192.168.1.106', 'Mozilla/5.0 (Linux; Android 14; SM-G991B)', '{"login_method": "social"}'),
(5, 'registration', '2024-03-01 11:40:00', 'desktop', 'Edge', '192.168.1.107', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '{"registration_source": "mobile"}'),
(7, 'password_reset', '2024-03-01 13:15:00', 'mobile', 'Safari', '192.168.1.108', 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)', '{"reset_method": "sms"}'),
(9, 'logout', '2024-03-01 17:20:00', 'desktop', 'Chrome', '192.168.1.109', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '{"session_duration": 2400}'); 