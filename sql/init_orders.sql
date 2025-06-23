-- ORDERS DOMAIN - Аналитика интернет-магазина
-- Шардирование по user_id:
-- user_id % 2 = 0 → shard_0
-- user_id % 2 = 1 → shard_1

-- Подключаем расширение для UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Таблицы заказов (шардированные)
CREATE TABLE orders_shard_0 (
    order_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount NUMERIC(10, 2),
    status VARCHAR(20), -- 'PENDING', 'PAID', 'SHIPPED', 'DELIVERED', 'CANCELLED'
    payment_method VARCHAR(50), -- 'CARD', 'PAYPAL', 'CASH', 'CRYPTO'
    shipping_address TEXT,
    delivery_method VARCHAR(50), -- 'STANDARD', 'EXPRESS', 'PICKUP'
    discount_amount NUMERIC(10, 2) DEFAULT 0,
    tax_amount NUMERIC(10, 2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'RUB'
);

CREATE TABLE orders_shard_1 (
    order_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount NUMERIC(10, 2),
    status VARCHAR(20),
    payment_method VARCHAR(50),
    shipping_address TEXT,
    delivery_method VARCHAR(50),
    discount_amount NUMERIC(10, 2) DEFAULT 0,
    tax_amount NUMERIC(10, 2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'RUB'
);

-- Таблицы позиций в заказе (шардированные)
CREATE TABLE order_items_shard_0 (
    item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    product_name VARCHAR(200),
    quantity INT,
    unit_price NUMERIC(10, 2),
    total_price NUMERIC(10, 2),
    category VARCHAR(100),
    brand VARCHAR(100)
);

CREATE TABLE order_items_shard_1 (
    item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    product_name VARCHAR(200),
    quantity INT,
    unit_price NUMERIC(10, 2),
    total_price NUMERIC(10, 2),
    category VARCHAR(100),
    brand VARCHAR(100)
);

-- Платежи (без шардинга - централизованная таблица)
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    user_id INT NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount NUMERIC(10, 2),
    payment_method VARCHAR(50),
    status VARCHAR(20), -- 'PENDING', 'SUCCESS', 'FAILED', 'REFUNDED'
    transaction_id VARCHAR(100),
    gateway VARCHAR(50), -- 'STRIPE', 'PAYPAL', 'SBERBANK', 'YANDEX'
    currency VARCHAR(3) DEFAULT 'RUB'
);

-- Возвраты (без шардинга)
CREATE TABLE returns (
    return_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    user_id INT NOT NULL,
    return_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason VARCHAR(200),
    status VARCHAR(20), -- 'PENDING', 'APPROVED', 'REJECTED', 'COMPLETED'
    refund_amount NUMERIC(10, 2),
    return_method VARCHAR(50) -- 'PICKUP', 'COURIER', 'POST'
);

-- Индексы для оптимизации запросов
CREATE INDEX idx_orders_shard_0_user_id ON orders_shard_0(user_id);
CREATE INDEX idx_orders_shard_1_user_id ON orders_shard_1(user_id);
CREATE INDEX idx_orders_shard_0_date ON orders_shard_0(order_date);
CREATE INDEX idx_orders_shard_1_date ON orders_shard_1(order_date);
CREATE INDEX idx_orders_shard_0_status ON orders_shard_0(status);
CREATE INDEX idx_orders_shard_1_status ON orders_shard_1(status);

CREATE INDEX idx_items_shard_0_order_id ON order_items_shard_0(order_id);
CREATE INDEX idx_items_shard_1_order_id ON order_items_shard_1(order_id);
CREATE INDEX idx_items_shard_0_product_id ON order_items_shard_0(product_id);
CREATE INDEX idx_items_shard_1_product_id ON order_items_shard_1(product_id);
CREATE INDEX idx_items_shard_0_category ON order_items_shard_0(category);
CREATE INDEX idx_items_shard_1_category ON order_items_shard_1(category);

CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_payments_status ON payments(status);

CREATE INDEX idx_returns_order_id ON returns(order_id);
CREATE INDEX idx_returns_user_id ON returns(user_id);
CREATE INDEX idx_returns_date ON returns(return_date);

-- Тестовые данные
-- Заказы для shard_0 (четные user_id)
INSERT INTO orders_shard_0 (user_id, order_date, total_amount, status, payment_method, shipping_address, delivery_method, discount_amount, tax_amount) VALUES
(2, '2024-02-15 14:30:00', 2500.00, 'DELIVERED', 'CARD', 'Moscow, Tverskaya st. 1, apt. 10', 'EXPRESS', 100.00, 250.00),
(4, '2024-02-20 16:45:00', 1800.00, 'SHIPPED', 'PAYPAL', 'Saint Petersburg, Nevsky pr. 50, apt. 5', 'STANDARD', 0.00, 180.00),
(6, '2024-02-25 09:15:00', 3200.00, 'PAID', 'CARD', 'Kazan, Bauman st. 20, apt. 15', 'EXPRESS', 200.00, 320.00),
(8, '2024-03-01 12:20:00', 1500.00, 'PENDING', 'CASH', 'Novosibirsk, Krasny pr. 100, apt. 8', 'PICKUP', 50.00, 150.00),
(10, '2024-03-01 18:30:00', 4200.00, 'CANCELLED', 'CARD', 'Yekaterinburg, Lenin st. 30, apt. 12', 'STANDARD', 0.00, 420.00);

-- Заказы для shard_1 (нечетные user_id)
INSERT INTO orders_shard_1 (user_id, order_date, total_amount, status, payment_method, shipping_address, delivery_method, discount_amount, tax_amount) VALUES
(1, '2024-02-10 10:00:00', 1500.00, 'DELIVERED', 'CARD', 'Moscow, Arbat st. 15, apt. 3', 'STANDARD', 0.00, 150.00),
(3, '2024-02-18 15:30:00', 2800.00, 'SHIPPED', 'PAYPAL', 'Saint Petersburg, Liteiny pr. 25, apt. 7', 'EXPRESS', 150.00, 280.00),
(5, '2024-02-22 11:45:00', 1900.00, 'PAID', 'CARD', 'Kazan, Kremlevskaya st. 10, apt. 20', 'STANDARD', 100.00, 190.00),
(7, '2024-02-28 13:20:00', 3500.00, 'PENDING', 'CARD', 'Novosibirsk, Gogol st. 5, apt. 11', 'EXPRESS', 200.00, 350.00),
(9, '2024-03-01 17:10:00', 2200.00, 'CANCELLED', 'PAYPAL', 'Yekaterinburg, Mira st. 40, apt. 6', 'PICKUP', 0.00, 220.00);

-- Позиции заказов для shard_0
INSERT INTO order_items_shard_0 (order_id, product_id, product_name, quantity, unit_price, total_price, category, brand) VALUES
(1, 101, 'iPhone 15 Pro Max 256GB', 1, 120000.00, 120000.00, 'Smartphones', 'Apple'),
(1, 102, 'AirPods Pro 2', 1, 25000.00, 25000.00, 'Audio', 'Apple'),
(2, 103, 'MacBook Air M2 13"', 1, 150000.00, 150000.00, 'Laptops', 'Apple'),
(2, 104, 'Magic Mouse', 1, 8000.00, 8000.00, 'Accessories', 'Apple'),
(3, 105, 'Samsung Galaxy S24 Ultra', 1, 140000.00, 140000.00, 'Smartphones', 'Samsung'),
(3, 106, 'Galaxy Buds Pro', 1, 18000.00, 18000.00, 'Audio', 'Samsung'),
(4, 107, 'Dell XPS 13', 1, 120000.00, 120000.00, 'Laptops', 'Dell'),
(5, 108, 'Sony WH-1000XM5', 1, 35000.00, 35000.00, 'Audio', 'Sony');

-- Позиции заказов для shard_1
INSERT INTO order_items_shard_1 (order_id, product_id, product_name, quantity, unit_price, total_price, category, brand) VALUES
(1, 201, 'iPad Pro 12.9" M2', 1, 180000.00, 180000.00, 'Tablets', 'Apple'),
(2, 202, 'Sony A7 IV Camera', 1, 250000.00, 250000.00, 'Cameras', 'Sony'),
(2, 203, 'Sony 24-70mm Lens', 1, 80000.00, 80000.00, 'Lenses', 'Sony'),
(3, 204, 'Logitech MX Master 3S', 1, 12000.00, 12000.00, 'Accessories', 'Logitech'),
(4, 205, 'LG OLED C3 65"', 1, 180000.00, 180000.00, 'TVs', 'LG'),
(4, 206, 'Samsung Soundbar Q990C', 1, 120000.00, 120000.00, 'Audio', 'Samsung'),
(5, 207, 'Nike Air Max 270', 1, 15000.00, 15000.00, 'Shoes', 'Nike');

-- Платежи
INSERT INTO payments (order_id, user_id, payment_date, amount, payment_method, status, transaction_id, gateway) VALUES
(1, 2, '2024-02-15 14:35:00', 2500.00, 'CARD', 'SUCCESS', 'txn_001_20240215', 'SBERBANK'),
(2, 4, '2024-02-20 16:50:00', 1800.00, 'PAYPAL', 'SUCCESS', 'txn_002_20240220', 'PAYPAL'),
(3, 6, '2024-02-25 09:20:00', 3200.00, 'CARD', 'SUCCESS', 'txn_003_20240225', 'YANDEX'),
(4, 8, '2024-03-01 12:25:00', 1500.00, 'CASH', 'PENDING', 'txn_004_20240301', 'CASH'),
(5, 10, '2024-03-01 18:35:00', 4200.00, 'CARD', 'FAILED', 'txn_005_20240301', 'SBERBANK'),
(1, 1, '2024-02-10 10:05:00', 1500.00, 'CARD', 'SUCCESS', 'txn_006_20240210', 'SBERBANK'),
(2, 3, '2024-02-18 15:35:00', 2800.00, 'PAYPAL', 'SUCCESS', 'txn_007_20240218', 'PAYPAL'),
(3, 5, '2024-02-22 11:50:00', 1900.00, 'CARD', 'SUCCESS', 'txn_008_20240222', 'YANDEX'),
(4, 7, '2024-02-28 13:25:00', 3500.00, 'CARD', 'PENDING', 'txn_009_20240228', 'SBERBANK'),
(5, 9, '2024-03-01 17:15:00', 2200.00, 'PAYPAL', 'FAILED', 'txn_010_20240301', 'PAYPAL');

-- Возвраты
INSERT INTO returns (order_id, user_id, return_date, reason, status, refund_amount, return_method) VALUES
(5, 10, '2024-03-02 10:00:00', 'Не подошел размер', 'APPROVED', 4200.00, 'COURIER'),
(5, 9, '2024-03-02 14:30:00', 'Поврежден при доставке', 'APPROVED', 2200.00, 'PICKUP'); 