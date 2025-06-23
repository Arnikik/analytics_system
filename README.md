# Система аналитики для интернет-магазина

## Описание проекта

Система аналитики для интернет-магазина представляет собой микросервисную архитектуру с горизонтальным шардингом базы данных PostgreSQL. Система предназначена для сбора, хранения и анализа данных о поведении пользователей, заказах и взаимодействии с товарами.

## Архитектура системы

### Микросервисы
- **Прокси-сервер** (порт 5435) - маршрутизация запросов между шардами
- **Users Domain** (порт 5432) - управление пользователями
- **Orders Domain** (порт 5433) - управление заказами
- **Analytics Domain** (порт 5434) - аналитические данные

### Шардинг
Система использует горизонтальный шардинг по `user_id`:
- `user_id % 2 = 0` → shard_0
- `user_id % 2 = 1` → shard_1

### Мониторинг
- **Prometheus** (порт 9090) - сбор метрик
- **Grafana** (порт 3000) - визуализация данных
- **AlertManager** (порт 9093) - управление алертами

## Структура данных

### Users Domain
- `users_shard_0/1` - основная информация о пользователях
- `user_profiles_shard_0/1` - профили пользователей
- `user_sessions_shard_0/1` - сессии пользователей

### Orders Domain
- `orders_shard_0/1` - заказы
- `order_items_shard_0/1` - позиции в заказах
- `payments` - платежи (централизованная таблица)
- `returns` - возвраты (централизованная таблица)

### Analytics Domain
- `product_views_shard_0/1` - просмотры товаров
- `click_logs_shard_0/1` - клики пользователей
- `search_history` - история поиска
- `cart_items_shard_0/1` - корзина покупок
- `wishlist_items_shard_0/1` - избранное
- `product_reviews` - отзывы о товарах
- `user_events_shard_0/1` - события пользователей

## Установка и запуск

### Предварительные требования
- Docker
- Docker Compose
- Java 11+ (для тестирования)
- Python 3.7+ (для нагрузочного тестирования)

### Запуск системы

1. **Клонирование репозитория**
```bash
git clone <repository-url>
cd analytics_system
```

2. **Запуск всех сервисов**
```bash
docker-compose up -d
```

3. **Проверка статуса**
```bash
docker-compose ps
```

### Порты сервисов
- Прокси-сервер: `localhost:5435`
- Users Domain: `localhost:5432`
- Orders Domain: `localhost:5433`
- Analytics Domain: `localhost:5434`
- Prometheus: `localhost:9090`
- Grafana: `localhost:3000`
- AlertManager: `localhost:9093`

## Тестирование

### Тестирование шардинга (Java)
```bash
# Компиляция
javac -cp "lib/postgresql-42.2.18.jar" lib/ShardConnection.java

# Запуск
java -cp "lib:lib/postgresql-42.2.18.jar" ShardConnection
```

### Нагрузочное тестирование (Python)
```bash
# Установка зависимостей
pip install psycopg2-binary

# Запуск тестирования
python load_test.py --threads 10 --duration 60 --rps 100
```

### Параметры нагрузочного тестирования
- `--threads` - количество потоков (по умолчанию: 10)
- `--duration` - длительность теста в секундах (по умолчанию: 60)
- `--rps` - запросов в секунду (по умолчанию: 100)

## Мониторинг и алерты

### Prometheus
- URL: http://localhost:9090
- Метрики PostgreSQL, Node Exporter
- Правила алертов в `monitoring/alerts.yml`

### Grafana
- URL: http://localhost:3000
- Логин: `admin`
- Пароль: `admin`
- Предустановленные дашборды для аналитики

### AlertManager
- URL: http://localhost:9093
- Настройки в `monitoring/alertmanager.yml`

## Аналитические запросы

### Топ категорий по просмотрам
```sql
SELECT category, COUNT(*) as views 
FROM product_views 
GROUP BY category 
ORDER BY views DESC 
LIMIT 5;
```

### Конверсия просмотров в заказы
```sql
SELECT 
    COUNT(DISTINCT pv.user_id) as users_with_views,
    COUNT(DISTINCT o.user_id) as users_with_orders,
    ROUND(COUNT(DISTINCT o.user_id) * 100.0 / COUNT(DISTINCT pv.user_id), 2) as conversion_rate
FROM product_views pv
LEFT JOIN orders o ON pv.user_id = o.user_id;
```

### Статистика заказов по статусам
```sql
SELECT status, COUNT(*) as count, AVG(total_amount) as avg_amount 
FROM orders 
GROUP BY status 
ORDER BY count DESC;
```

### Топ брендов по кликам
```sql
SELECT brand, COUNT(*) as clicks 
FROM click_logs cl
JOIN product_views pv ON cl.user_id = pv.user_id 
GROUP BY brand 
ORDER BY clicks DESC 
LIMIT 5;
```

## Производительность

### Оптимизация
- Индексы на ключевых полях
- Шардинг по user_id для равномерного распределения нагрузки
- Партиционирование по времени для больших таблиц
- Кэширование частых запросов

### Метрики производительности
- Время отклика запросов
- Количество активных соединений
- Использование CPU и памяти
- Количество транзакций в секунду

## Безопасность

### Аутентификация
- Пользователь: `admin`
- Пароль: `admin`
- Рекомендуется изменить в продакшене

### Сетевая безопасность
- Изоляция контейнеров
- Ограничение доступа к портам
- Шифрование соединений (в продакшене)

## Масштабирование

### Горизонтальное масштабирование
- Добавление новых шардов
- Репликация для чтения
- Балансировка нагрузки

### Вертикальное масштабирование
- Увеличение ресурсов контейнеров
- Оптимизация запросов
- Настройка PostgreSQL

## Логирование

### Логи Docker
```bash
# Просмотр логов всех сервисов
docker-compose logs

# Логи конкретного сервиса
docker-compose logs postgres-proxy
```

### Логи PostgreSQL
- Логи запросов
- Логи ошибок
- Медленные запросы

## Резервное копирование

### Создание бэкапа
```bash
# Бэкап всех баз данных
docker-compose exec postgres-users pg_dump -U admin analytics_users > backup_users.sql
docker-compose exec postgres-orders pg_dump -U admin analytics_orders > backup_orders.sql
docker-compose exec postgres-analytics pg_dump -U admin analytics_data > backup_analytics.sql
```

### Восстановление
```bash
# Восстановление из бэкапа
docker-compose exec -T postgres-users psql -U admin analytics_users < backup_users.sql
docker-compose exec -T postgres-orders psql -U admin analytics_orders < backup_orders.sql
docker-compose exec -T postgres-analytics psql -U admin analytics_data < backup_analytics.sql
```

## Устранение неполадок

### Проблемы с подключением
1. Проверьте статус контейнеров: `docker-compose ps`
2. Проверьте логи: `docker-compose logs <service-name>`
3. Проверьте сетевые настройки: `docker network ls`

### Проблемы с производительностью
1. Мониторинг через Grafana
2. Анализ медленных запросов
3. Проверка индексов
4. Оптимизация конфигурации PostgreSQL

### Проблемы с шардингом
1. Проверьте функции маршрутизации
2. Проверьте триггеры
3. Проверьте внешние таблицы

## Разработка

### Добавление новых таблиц
1. Создайте схему в соответствующем домене
2. Добавьте внешние таблицы в прокси
3. Создайте триггеры для маршрутизации
4. Обновите индексы

### Добавление новых метрик
1. Добавьте метрики в Prometheus
2. Создайте дашборд в Grafana
3. Настройте алерты при необходимости

## Лицензия

MIT License

## Авторы

Система аналитики для интернет-магазина 