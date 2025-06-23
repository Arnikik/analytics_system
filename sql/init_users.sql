-- USERS DOMAIN - Аналитика интернет-магазина
-- Шардирование по user_id:
-- user_id % 2 = 0 → shard_0
-- user_id % 2 = 1 → shard_1

-- Таблицы пользователей
CREATE TABLE users_shard_0 (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users_shard_1 (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Профили пользователей (шардированные)
CREATE TABLE user_profiles_shard_0 (
    profile_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone_number VARCHAR(20),
    birthdate DATE,
    city VARCHAR(100),
    region VARCHAR(100),
    country VARCHAR(50),
    registration_source VARCHAR(50), -- 'web', 'mobile', 'social'
    is_premium BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMP
);

CREATE TABLE user_profiles_shard_1 (
    profile_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone_number VARCHAR(20),
    birthdate DATE,
    city VARCHAR(100),
    region VARCHAR(100),
    country VARCHAR(50),
    registration_source VARCHAR(50),
    is_premium BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMP
);

-- Сессии пользователей (шардированные)
CREATE TABLE user_sessions_shard_0 (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INT NOT NULL,
    session_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_end TIMESTAMP,
    device_type VARCHAR(50), -- 'desktop', 'mobile', 'tablet'
    browser VARCHAR(50),
    ip_address INET,
    user_agent TEXT
);

CREATE TABLE user_sessions_shard_1 (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INT NOT NULL,
    session_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_end TIMESTAMP,
    device_type VARCHAR(50),
    browser VARCHAR(50),
    ip_address INET,
    user_agent TEXT
);

-- Индексы для оптимизации запросов
CREATE INDEX idx_users_shard_0_email ON users_shard_0(email);
CREATE INDEX idx_users_shard_1_email ON users_shard_1(email);
CREATE INDEX idx_users_shard_0_registration_date ON users_shard_0(registration_date);
CREATE INDEX idx_users_shard_1_registration_date ON users_shard_1(registration_date);

CREATE INDEX idx_profiles_shard_0_user_id ON user_profiles_shard_0(user_id);
CREATE INDEX idx_profiles_shard_1_user_id ON user_profiles_shard_1(user_id);
CREATE INDEX idx_profiles_shard_0_city ON user_profiles_shard_0(city);
CREATE INDEX idx_profiles_shard_1_city ON user_profiles_shard_1(city);

CREATE INDEX idx_sessions_shard_0_user_id ON user_sessions_shard_0(user_id);
CREATE INDEX idx_sessions_shard_1_user_id ON user_sessions_shard_1(user_id);
CREATE INDEX idx_sessions_shard_0_start ON user_sessions_shard_0(session_start);
CREATE INDEX idx_sessions_shard_1_start ON user_sessions_shard_1(session_start);

-- Тестовые данные
-- Пользователи с четными ID (shard_0)
INSERT INTO users_shard_0 (user_id, username, email, registration_date) VALUES
(2, 'alice_smith', 'alice.smith@example.com', '2024-01-15 10:30:00'),
(4, 'bob_johnson', 'bob.johnson@example.com', '2024-01-20 14:45:00'),
(6, 'carol_lee', 'carol.lee@example.com', '2024-02-01 09:15:00'),
(8, 'david_wilson', 'david.wilson@example.com', '2024-02-10 16:20:00'),
(10, 'emma_brown', 'emma.brown@example.com', '2024-02-15 11:30:00');

-- Пользователи с нечетными ID (shard_1)
INSERT INTO users_shard_1 (user_id, username, email, registration_date) VALUES
(1, 'john_doe', 'john.doe@example.com', '2024-01-10 08:00:00'),
(3, 'jane_smith', 'jane.smith@example.com', '2024-01-18 12:30:00'),
(5, 'mike_davis', 'mike.davis@example.com', '2024-01-25 15:45:00'),
(7, 'sarah_miller', 'sarah.miller@example.com', '2024-02-05 13:20:00'),
(9, 'tom_anderson', 'tom.anderson@example.com', '2024-02-12 10:10:00');

-- Профили для shard_0
INSERT INTO user_profiles_shard_0 (user_id, first_name, last_name, phone_number, birthdate, city, region, country, registration_source, is_premium, last_login) VALUES
(2, 'Alice', 'Smith', '+71234567890', '1990-05-15', 'Moscow', 'Moscow Region', 'Russia', 'web', FALSE, '2024-03-01 14:30:00'),
(4, 'Bob', 'Johnson', '+79876543210', '1985-08-20', 'Saint Petersburg', 'Leningrad Region', 'Russia', 'mobile', TRUE, '2024-03-01 16:45:00'),
(6, 'Carol', 'Lee', '+79111222333', '1992-12-10', 'Kazan', 'Tatarstan', 'Russia', 'social', FALSE, '2024-03-01 09:15:00'),
(8, 'David', 'Wilson', '+79444555666', '1988-03-25', 'Novosibirsk', 'Novosibirsk Region', 'Russia', 'web', TRUE, '2024-03-01 12:20:00'),
(10, 'Emma', 'Brown', '+79777888999', '1995-07-08', 'Yekaterinburg', 'Sverdlovsk Region', 'Russia', 'mobile', FALSE, '2024-03-01 18:30:00');

-- Профили для shard_1
INSERT INTO user_profiles_shard_1 (user_id, first_name, last_name, phone_number, birthdate, city, region, country, registration_source, is_premium, last_login) VALUES
(1, 'John', 'Doe', '+71111111111', '1987-11-12', 'Moscow', 'Moscow Region', 'Russia', 'web', TRUE, '2024-03-01 10:00:00'),
(3, 'Jane', 'Smith', '+72222222222', '1991-04-18', 'Saint Petersburg', 'Leningrad Region', 'Russia', 'mobile', FALSE, '2024-03-01 15:30:00'),
(5, 'Mike', 'Davis', '+73333333333', '1983-09-30', 'Kazan', 'Tatarstan', 'Russia', 'social', TRUE, '2024-03-01 11:45:00'),
(7, 'Sarah', 'Miller', '+74444444444', '1989-06-14', 'Novosibirsk', 'Novosibirsk Region', 'Russia', 'web', FALSE, '2024-03-01 13:20:00'),
(9, 'Tom', 'Anderson', '+75555555555', '1993-01-22', 'Yekaterinburg', 'Sverdlovsk Region', 'Russia', 'mobile', TRUE, '2024-03-01 17:10:00');

-- Сессии для shard_0
INSERT INTO user_sessions_shard_0 (user_id, session_start, session_end, device_type, browser, ip_address, user_agent) VALUES
(2, '2024-03-01 14:30:00', '2024-03-01 15:45:00', 'desktop', 'Chrome', '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'),
(4, '2024-03-01 16:45:00', '2024-03-01 17:30:00', 'mobile', 'Safari', '192.168.1.101', 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)'),
(6, '2024-03-01 09:15:00', '2024-03-01 10:30:00', 'tablet', 'Chrome', '192.168.1.102', 'Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X)');

-- Сессии для shard_1
INSERT INTO user_sessions_shard_1 (user_id, session_start, session_end, device_type, browser, ip_address, user_agent) VALUES
(1, '2024-03-01 10:00:00', '2024-03-01 11:15:00', 'desktop', 'Firefox', '192.168.1.103', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0)'),
(3, '2024-03-01 15:30:00', '2024-03-01 16:45:00', 'mobile', 'Chrome', '192.168.1.104', 'Mozilla/5.0 (Linux; Android 14; SM-G991B)'),
(5, '2024-03-01 11:45:00', '2024-03-01 12:30:00', 'desktop', 'Edge', '192.168.1.105', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'); 