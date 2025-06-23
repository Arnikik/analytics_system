#!/usr/bin/env python3
"""
Нагрузочное тестирование системы аналитики интернет-магазина
"""

import psycopg2
import time
import random
import threading
import argparse
from datetime import datetime, timedelta
import uuid

class AnalyticsLoadTester:
    def __init__(self, host='localhost', port=5435, dbname='analytics_proxy', 
                 user='admin', password='admin'):
        self.connection_params = {
            'host': host,
            'port': port,
            'dbname': dbname,
            'user': user,
            'password': password
        }
        self.stats = {
            'total_requests': 0,
            'successful_requests': 0,
            'failed_requests': 0,
            'total_time': 0,
            'start_time': None
        }
        self.lock = threading.Lock()

    def get_connection(self):
        """Получение соединения с базой данных"""
        return psycopg2.connect(**self.connection_params)

    def simulate_user_registration(self, user_id):
        """Симуляция регистрации пользователя"""
        try:
            with self.get_connection() as conn:
                with conn.cursor() as cur:
                    username = f"load_test_user_{user_id}"
                    email = f"load_test_{user_id}@example.com"
                    
                    cur.execute("""
                        INSERT INTO users (user_id, username, email) 
                        VALUES (%s, %s, %s)
                    """, (user_id, username, email))
                    
                    conn.commit()
                    return True
        except Exception as e:
            print(f"Ошибка при регистрации пользователя {user_id}: {e}")
            return False

    def simulate_product_view(self, user_id):
        """Симуляция просмотра товара"""
        try:
            with self.get_connection() as conn:
                with conn.cursor() as cur:
                    product_id = random.randint(1000, 9999)
                    product_name = f"Product {product_id}"
                    category = random.choice(['Smartphones', 'Laptops', 'Audio', 'Accessories', 'TVs'])
                    brand = random.choice(['Apple', 'Samsung', 'Sony', 'Dell', 'LG'])
                    cur.execute("""
                        INSERT INTO product_views (user_id, product_id, product_name, category, brand)
                        VALUES (%s, %s, %s, %s, %s)
                    """, (user_id, product_id, product_name, category, brand))
                    conn.commit()
                    return True
        except Exception as e:
            print(f"Ошибка при просмотре товара пользователем {user_id}: {e}")
            return False

    def simulate_click(self, user_id):
        """Симуляция клика (удалено, так как таблицы click_logs нет)"""
        return True

    def simulate_order(self, user_id):
        """Симуляция заказа"""
        try:
            with self.get_connection() as conn:
                with conn.cursor() as cur:
                    # Генерируем данные заказа
                    total_amount = random.uniform(1000, 50000)
                    status = random.choice(['PENDING', 'PAID', 'SHIPPED', 'DELIVERED'])
                    payment_method = random.choice(['CARD', 'PAYPAL', 'CASH', 'CRYPTO'])
                    shipping_address = f"Test Address {user_id}, Apt. {random.randint(1, 100)}"
                    delivery_method = random.choice(['STANDARD', 'EXPRESS', 'PICKUP'])
                    discount_amount = random.uniform(0, total_amount * 0.2)  # До 20% скидки
                    tax_amount = total_amount * 0.2  # 20% НДС
                    currency = 'RUB'

                    # Создаем заказ
                    cur.execute("""
                        INSERT INTO orders (
                            user_id, total_amount, status, payment_method, 
                            shipping_address, delivery_method, discount_amount, 
                            tax_amount, currency
                        ) VALUES (
                            %s, %s, %s, %s, %s, %s, %s, %s, %s
                        ) RETURNING order_id
                    """, (
                        user_id, total_amount, status, payment_method,
                        shipping_address, delivery_method, discount_amount,
                        tax_amount, currency
                    ))
                    order_id = cur.fetchone()[0]

                    # Добавляем 1-3 товара в заказ
                    num_items = random.randint(1, 3)
                    for _ in range(num_items):
                        product_id = random.randint(1000, 9999)
                        product_name = f"Product {product_id}"
                        quantity = random.randint(1, 5)
                        unit_price = random.uniform(500, 10000)
                        total_price = quantity * unit_price
                        category = random.choice(['Smartphones', 'Laptops', 'Audio', 'Accessories', 'TVs'])
                        brand = random.choice(['Apple', 'Samsung', 'Sony', 'Dell', 'LG'])

                        cur.execute("""
                            INSERT INTO order_items (
                                order_id, product_id, product_name, quantity,
                                unit_price, total_price, category, brand
                            ) VALUES (
                                %s, %s, %s, %s, %s, %s, %s, %s
                            )
                        """, (
                            order_id, product_id, product_name, quantity,
                            unit_price, total_price, category, brand
                        ))

                    # Создаем запись об оплате
                    if status in ['PAID', 'SHIPPED', 'DELIVERED']:
                        transaction_id = f"txn_{order_id}_{int(time.time())}"
                        gateway = random.choice(['STRIPE', 'PAYPAL', 'SBERBANK', 'YANDEX'])
                        cur.execute("""
                            INSERT INTO payments (
                                order_id, user_id, amount, payment_method,
                                status, transaction_id, gateway, currency
                            ) VALUES (
                                %s, %s, %s, %s, %s, %s, %s, %s
                            )
                        """, (
                            order_id, user_id, total_amount, payment_method,
                            'SUCCESS', transaction_id, gateway, currency
                        ))

                    conn.commit()
                    return True
        except Exception as e:
            print(f"Ошибка при создании заказа пользователем {user_id}: {e}")
            return False

    def simulate_search(self, user_id):
        """Симуляция поиска (только существующие поля, без search_id)"""
        try:
            with self.get_connection() as conn:
                with conn.cursor() as cur:
                    search_queries = [
                        'iphone 15 pro max', 'ноутбуки для работы', 'камера sony',
                        'беспроводные наушники', 'игровая мышь', 'samsung galaxy',
                        'телевизор 4k', 'dell xps', 'кроссовки nike', 'airpods pro'
                    ]
                    query = random.choice(search_queries)
                    results_count = random.randint(5, 50)
                    cur.execute("""
                        INSERT INTO search_history (user_id, query_text, results_count)
                        VALUES (%s, %s, %s)
                    """, (user_id, query, results_count))
                    conn.commit()
                    return True
        except Exception as e:
            print(f"Ошибка при поиске пользователем {user_id}: {e}")
            return False

    def simulate_analytics_query(self):
        """Симуляция аналитического запроса"""
        try:
            with self.get_connection() as conn:
                with conn.cursor() as cur:
                    # Топ категорий по просмотрам
                    cur.execute("""
                        SELECT category, COUNT(*) as views 
                        FROM product_views 
                        GROUP BY category 
                        ORDER BY views DESC 
                        LIMIT 5
                    """)
                    cur.fetchall()
                    
                    # Статистика заказов
                    cur.execute("""
                        SELECT status, COUNT(*) as count, AVG(total_amount) as avg_amount 
                        FROM orders 
                        GROUP BY status 
                        ORDER BY count DESC
                    """)
                    cur.fetchall()
                    
                    return True
        except Exception as e:
            print(f"Ошибка при выполнении аналитического запроса: {e}")
            return False

    def reset_sequences(self):
        """Сброс sequence для всех таблиц с автоинкрементными PK"""
        try:
            with self.get_connection() as conn:
                with conn.cursor() as cur:
                    # product_views_shard_0
                    try:
                        cur.execute("SELECT COALESCE(MAX(view_id), 0) + 1 FROM product_views_shard_0")
                        next_id_0 = cur.fetchone()[0]
                        cur.execute(f"ALTER SEQUENCE product_views_shard_0_view_id_seq RESTART WITH {next_id_0}")
                    except Exception as e:
                        print(f'Ошибка при сбросе sequence product_views_shard_0: {e}')
                    # product_views_shard_1
                    try:
                        cur.execute("SELECT COALESCE(MAX(view_id), 0) + 1 FROM product_views_shard_1")
                        next_id_1 = cur.fetchone()[0]
                        cur.execute(f"ALTER SEQUENCE product_views_shard_1_view_id_seq RESTART WITH {next_id_1}")
                    except Exception as e:
                        print(f'Ошибка при сбросе sequence product_views_shard_1: {e}')
                    # search_history
                    try:
                        cur.execute("SELECT COALESCE(MAX(search_id), 0) + 1 FROM search_history")
                        next_search_id = cur.fetchone()[0]
                        cur.execute(f"ALTER SEQUENCE search_history_search_id_seq RESTART WITH {next_search_id}")
                    except Exception as e:
                        print(f'Ошибка при сбросе sequence search_history: {e}')
                    # orders_shard_0
                    try:
                        cur.execute("SELECT COALESCE(MAX(order_id), 0) + 1 FROM orders_shard_0")
                        next_order_0 = cur.fetchone()[0]
                        cur.execute(f"ALTER SEQUENCE orders_shard_0_order_id_seq RESTART WITH {next_order_0}")
                    except Exception as e:
                        print(f'Ошибка при сбросе sequence orders_shard_0: {e}')
                    # orders_shard_1
                    try:
                        cur.execute("SELECT COALESCE(MAX(order_id), 0) + 1 FROM orders_shard_1")
                        next_order_1 = cur.fetchone()[0]
                        cur.execute(f"ALTER SEQUENCE orders_shard_1_order_id_seq RESTART WITH {next_order_1}")
                    except Exception as e:
                        print(f'Ошибка при сбросе sequence orders_shard_1: {e}')
                    # order_items_shard_0
                    try:
                        cur.execute("SELECT COALESCE(MAX(item_id), 0) + 1 FROM order_items_shard_0")
                        next_item_0 = cur.fetchone()[0]
                        cur.execute(f"ALTER SEQUENCE order_items_shard_0_item_id_seq RESTART WITH {next_item_0}")
                    except Exception as e:
                        print(f'Ошибка при сбросе sequence order_items_shard_0: {e}')
                    # order_items_shard_1
                    try:
                        cur.execute("SELECT COALESCE(MAX(item_id), 0) + 1 FROM order_items_shard_1")
                        next_item_1 = cur.fetchone()[0]
                        cur.execute(f"ALTER SEQUENCE order_items_shard_1_item_id_seq RESTART WITH {next_item_1}")
                    except Exception as e:
                        print(f'Ошибка при сбросе sequence order_items_shard_1: {e}')
                    # payments
                    try:
                        cur.execute("SELECT COALESCE(MAX(payment_id), 0) + 1 FROM payments")
                        next_payment_id = cur.fetchone()[0]
                        cur.execute(f"ALTER SEQUENCE payments_payment_id_seq RESTART WITH {next_payment_id}")
                    except Exception as e:
                        print(f'Ошибка при сбросе sequence payments: {e}')
                    # returns
                    try:
                        cur.execute("SELECT COALESCE(MAX(return_id), 0) + 1 FROM returns")
                        next_return_id = cur.fetchone()[0]
                        cur.execute(f"ALTER SEQUENCE returns_return_id_seq RESTART WITH {next_return_id}")
                    except Exception as e:
                        print(f'Ошибка при сбросе sequence returns: {e}')
                    # user_events_shard_0
                    try:
                        cur.execute("SELECT COALESCE(MAX(event_id), 0) + 1 FROM user_events_shard_0")
                        next_event_0 = cur.fetchone()[0]
                        cur.execute(f"ALTER SEQUENCE user_events_shard_0_event_id_seq RESTART WITH {next_event_0}")
                    except Exception as e:
                        print(f'Ошибка при сбросе sequence user_events_shard_0: {e}')
                    # user_events_shard_1
                    try:
                        cur.execute("SELECT COALESCE(MAX(event_id), 0) + 1 FROM user_events_shard_1")
                        next_event_1 = cur.fetchone()[0]
                        cur.execute(f"ALTER SEQUENCE user_events_shard_1_event_id_seq RESTART WITH {next_event_1}")
                    except Exception as e:
                        print(f'Ошибка при сбросе sequence user_events_shard_1: {e}')
                    # wishlist_items_shard_0
                    try:
                        cur.execute("SELECT COALESCE(MAX(wishlist_item_id), 0) + 1 FROM wishlist_items_shard_0")
                        next_wishlist_0 = cur.fetchone()[0]
                        cur.execute(f"ALTER SEQUENCE wishlist_items_shard_0_wishlist_item_id_seq RESTART WITH {next_wishlist_0}")
                    except Exception as e:
                        print(f'Ошибка при сбросе sequence wishlist_items_shard_0: {e}')
                    # wishlist_items_shard_1
                    try:
                        cur.execute("SELECT COALESCE(MAX(wishlist_item_id), 0) + 1 FROM wishlist_items_shard_1")
                        next_wishlist_1 = cur.fetchone()[0]
                        cur.execute(f"ALTER SEQUENCE wishlist_items_shard_1_wishlist_item_id_seq RESTART WITH {next_wishlist_1}")
                    except Exception as e:
                        print(f'Ошибка при сбросе sequence wishlist_items_shard_1: {e}')
                    # product_reviews
                    try:
                        cur.execute("SELECT COALESCE(MAX(review_id), 0) + 1 FROM product_reviews")
                        next_review_id = cur.fetchone()[0]
                        cur.execute(f"ALTER SEQUENCE product_reviews_review_id_seq RESTART WITH {next_review_id}")
                    except Exception as e:
                        print(f'Ошибка при сбросе sequence product_reviews: {e}')
                    conn.commit()
        except Exception as e:
            print(f'Ошибка при сбросе sequence: {e}')

    def worker(self, worker_id, duration, requests_per_second):
        """Рабочий поток для симуляции нагрузки"""
        end_time = time.time() + duration
        request_interval = 1.0 / requests_per_second
        
        while time.time() < end_time:
            start_time = time.time()
            
            # Генерируем случайный user_id
            user_id = random.randint(1, 1000)
            
            # Выбираем случайное действие
            action = random.choices(
                ['view', 'click', 'order', 'search', 'analytics'],
                weights=[0.4, 0.3, 0.1, 0.1, 0.1]
            )[0]
            
            success = False
            if action == 'view':
                success = self.simulate_product_view(user_id)
            elif action == 'click':
                success = self.simulate_click(user_id)
            elif action == 'order':
                success = self.simulate_order(user_id)
            elif action == 'search':
                success = self.simulate_search(user_id)
            elif action == 'analytics':
                success = self.simulate_analytics_query()
            
            # Обновляем статистику
            with self.lock:
                self.stats['total_requests'] += 1
                if success:
                    self.stats['successful_requests'] += 1
                else:
                    self.stats['failed_requests'] += 1
                self.stats['total_time'] += time.time() - start_time
            
            # Ждем до следующего запроса
            time.sleep(request_interval)

    def run_load_test(self, num_threads=10, duration=60, requests_per_second=100):
        """Запуск нагрузочного тестирования"""
        print(f"Запуск нагрузочного тестирования:")
        print(f"- Количество потоков: {num_threads}")
        print(f"- Длительность: {duration} секунд")
        print(f"- Запросов в секунду: {requests_per_second}")
        print(f"- Общее количество запросов: {num_threads * duration * requests_per_second}")
        print("-" * 50)
        self.reset_sequences()
        self.stats['start_time'] = time.time()
        
        # Создаем и запускаем потоки
        threads = []
        for i in range(num_threads):
            thread = threading.Thread(
                target=self.worker,
                args=(i, duration, requests_per_second / num_threads)
            )
            threads.append(thread)
            thread.start()
        
        # Ждем завершения всех потоков
        for thread in threads:
            thread.join()
        
        # Выводим результаты
        self.print_results()

    def print_results(self):
        """Вывод результатов тестирования"""
        total_time = time.time() - self.stats['start_time']
        
        print("\n" + "=" * 50)
        print("РЕЗУЛЬТАТЫ НАГРУЗОЧНОГО ТЕСТИРОВАНИЯ")
        print("=" * 50)
        print(f"Общее время выполнения: {total_time:.2f} секунд")
        print(f"Всего запросов: {self.stats['total_requests']}")
        print(f"Успешных запросов: {self.stats['successful_requests']}")
        print(f"Неудачных запросов: {self.stats['failed_requests']}")
        print(f"Процент успешных запросов: {(self.stats['successful_requests'] / self.stats['total_requests'] * 100):.2f}%")
        print(f"Среднее время запроса: {(self.stats['total_time'] / self.stats['total_requests'] * 1000):.2f} мс")
        print(f"Запросов в секунду: {self.stats['total_requests'] / total_time:.2f}")
        print("=" * 50)

def main():
    parser = argparse.ArgumentParser(description='Нагрузочное тестирование системы аналитики')
    parser.add_argument('--host', default='localhost', help='Хост базы данных')
    parser.add_argument('--port', type=int, default=5435, help='Порт базы данных')
    parser.add_argument('--dbname', default='analytics_proxy', help='Имя базы данных')
    parser.add_argument('--user', default='admin', help='Пользователь базы данных')
    parser.add_argument('--password', default='admin', help='Пароль базы данных')
    parser.add_argument('--threads', type=int, default=10, help='Количество потоков')
    parser.add_argument('--duration', type=int, default=60, help='Длительность теста в секундах')
    parser.add_argument('--rps', type=int, default=100, help='Запросов в секунду')
    
    args = parser.parse_args()
    
    # Создаем и запускаем тестер
    tester = AnalyticsLoadTester(
        host=args.host,
        port=args.port,
        dbname=args.dbname,
        user=args.user,
        password=args.password
    )
    
    try:
        tester.run_load_test(
            num_threads=args.threads,
            duration=args.duration,
            requests_per_second=args.rps
        )
    except KeyboardInterrupt:
        print("\nТестирование прервано пользователем")
    except Exception as e:
        print(f"Ошибка при выполнении тестирования: {e}")

if __name__ == "__main__":
    main() 
