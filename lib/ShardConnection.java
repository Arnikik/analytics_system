import java.sql.*;
import java.util.concurrent.Executors;

public class ShardConnection {
    private static final String PROXY_URL = "jdbc:postgresql://localhost:5435/analytics_proxy?sslmode=disable";
    private static final String USER = "admin";
    private static final String PASSWORD = "admin";
    private static final int QUERY_TIMEOUT_SEC = 5;
    private static final int MAX_DISPLAY_ROWS = 100;

    public static void main(String[] args) {
        System.out.println("Starting application...");
        try {
            Class.forName("org.postgresql.Driver");
            System.out.println("PostgreSQL driver loaded");

            DriverManager.setLoginTimeout(5);

            System.out.println("Trying to connect to: " + PROXY_URL);
            long startTime = System.currentTimeMillis();

            try (Connection conn = DriverManager.getConnection(PROXY_URL, USER, PASSWORD)) {
                long elapsed = System.currentTimeMillis() - startTime;
                System.out.printf("Connected successfully in %d ms%n", elapsed);

                if (args.length == 0 || args[0].equalsIgnoreCase("all")) {
                    testUsers(conn);
                    testOrders(conn);
                    testAnalytics(conn);
                    testAnalyticsQueries(conn);
                } else {
                    for (String arg : args) {
                        switch (arg.toLowerCase()) {
                            case "users": testUsers(conn); break;
                            case "orders": testOrders(conn); break;
                            case "analytics": testAnalytics(conn); break;
                            case "queries": testAnalyticsQueries(conn); break;
                            default:
                                System.out.println("Неизвестный тест: " + arg);
                        }
                    }
                }
            } catch (SQLException e) {
                System.err.println("Connection failed:");
                System.err.println("URL: " + PROXY_URL);
                System.err.println("User: " + USER);
                printSQLException(e);
            }
        } catch (ClassNotFoundException e) {
            System.err.println("PostgreSQL driver not found!");
            e.printStackTrace();
        } catch (Exception e) {
            System.err.println("Unexpected error:");
            e.printStackTrace();
        }
    }

    private static void printSQLException(SQLException ex) {
        for (Throwable e : ex) {
            if (e instanceof SQLException) {
                System.err.println("SQLState: " + ((SQLException) e).getSQLState());
                System.err.println("Error Code: " + ((SQLException) e).getErrorCode());
                System.err.println("Message: " + e.getMessage());
                Throwable t = ex.getCause();
                while (t != null) {
                    System.out.println("Cause: " + t);
                    t = t.getCause();
                }
            }
        }
    }

    private static void testUsers(Connection conn) throws SQLException {
    System.out.println("=== ТЕСТ ПОЛЬЗОВАТЕЛЕЙ ===");
    // Чистим тестовых пользователей напрямую из шардов
    executeUpdate(conn, "DELETE FROM users_shard_0 WHERE user_id IN (100, 101)");
    executeUpdate(conn, "DELETE FROM users_shard_1 WHERE user_id IN (100, 101)");

    executeUpdate(conn,
        "INSERT INTO users (user_id, username, email) VALUES " +
        "(100, 'test_user_even', 'test_even@example.com')");

    executeUpdate(conn,
        "INSERT INTO users (user_id, username, email) VALUES " +
        "(101, 'test_user_odd', 'test_odd@example.com')");

    System.out.println("Все пользователи:");
    executeQuery(conn, "SELECT * FROM users ORDER BY user_id");
    }

    private static void testOrders(Connection conn) throws SQLException {
    System.out.println("\n=== ТЕСТ ЗАКАЗОВ ===");
    // Чистим тестовые заказы напрямую из шардов
    executeUpdate(conn, "DELETE FROM orders_shard_0 WHERE user_id IN (100, 101)");
    executeUpdate(conn, "DELETE FROM orders_shard_1 WHERE user_id IN (100, 101)");
    // Сбрасываем sequence, чтобы не было конфликтов PK
    executeUpdate(conn, "ALTER SEQUENCE orders_shard_0_order_id_seq RESTART WITH 1000");
    executeUpdate(conn, "ALTER SEQUENCE orders_shard_1_order_id_seq RESTART WITH 1000");

    executeUpdate(conn,
        "INSERT INTO orders (user_id, total_amount, status) VALUES " +
        "(100, 50000.00, 'PAID')");

    executeUpdate(conn,
        "INSERT INTO orders (user_id, total_amount, status) VALUES " +
        "(101, 75000.00, 'PENDING')");

    System.out.println("Все заказы:");
    executeQuery(conn, "SELECT * FROM orders ORDER BY user_id");
    }

    private static void testAnalytics(Connection conn) throws SQLException {
    System.out.println("\n=== ТЕСТ АНАЛИТИКИ ===");
    // Чистим тестовые просмотры напрямую из шардов
    executeUpdate(conn, "DELETE FROM product_views_shard_0 WHERE user_id IN (100, 101)");
    executeUpdate(conn, "DELETE FROM product_views_shard_1 WHERE user_id IN (100, 101)");
    // Сбрасываем sequence, чтобы не было конфликтов PK
    executeUpdate(conn, "ALTER SEQUENCE product_views_shard_0_view_id_seq RESTART WITH 1000");
    executeUpdate(conn, "ALTER SEQUENCE product_views_shard_1_view_id_seq RESTART WITH 1000");

    executeUpdate(conn,
        "INSERT INTO product_views (user_id, product_id, product_name, category, brand) VALUES " +
        "(100, 1001, 'Test Product Even', 'Electronics', 'TestBrand')");

    executeUpdate(conn,
        "INSERT INTO product_views (user_id, product_id, product_name, category, brand) VALUES " +
        "(101, 1002, 'Test Product Odd', 'Clothing', 'TestBrand')");

    System.out.println("Просмотры товаров:");
    executeQuery(conn, "SELECT * FROM product_views ORDER BY user_id");
    }

    private static void testAnalyticsQueries(Connection conn) throws SQLException {
        System.out.println("\n=== ТЕСТ АНАЛИТИЧЕСКИХ ЗАПРОСОВ ===");
        System.out.println("Топ категорий по просмотрам:");
        executeQuery(conn, 
            "SELECT category, COUNT(*) as views " +
            "FROM product_views " +
            "GROUP BY category " +
            "ORDER BY views DESC " +
            "LIMIT 5");
        System.out.println("Статистика заказов по статусам:");
        executeQuery(conn,
            "SELECT status, COUNT(*) as count, AVG(total_amount) as avg_amount " +
            "FROM orders " +
            "GROUP BY status " +
            "ORDER BY count DESC");
        System.out.println("Конверсия просмотров в заказы:");
        executeQuery(conn,
            "SELECT " +
            "COUNT(DISTINCT pv.user_id) as users_with_views, " +
            "COUNT(DISTINCT o.user_id) as users_with_orders, " +
            "ROUND(COUNT(DISTINCT o.user_id) * 100.0 / COUNT(DISTINCT pv.user_id), 2) as conversion_rate " +
            "FROM product_views pv " +
            "LEFT JOIN orders o ON pv.user_id = o.user_id");
    }
    
    private static void executeUpdate(Connection conn, String sql) throws SQLException {
        System.out.println("Executing: " + sql);
        try (Statement stmt = conn.createStatement()) {
            stmt.setQueryTimeout(QUERY_TIMEOUT_SEC);
            int rowsAffected = stmt.executeUpdate(sql);
            System.out.println("Затронуто строк: " + rowsAffected);
        }
    }
    
    private static void executeQuery(Connection conn, String sql) throws SQLException {
        System.out.println("Querying: " + sql);
        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            stmt.setQueryTimeout(QUERY_TIMEOUT_SEC);
            printResultSet(rs);
        }
    }
    
    private static void printResultSet(ResultSet rs) throws SQLException {
        ResultSetMetaData meta = rs.getMetaData();
        int columns = meta.getColumnCount();
        int rowCount = 0;
        
        // Заголовки столбцов
        for (int i = 1; i <= columns; i++) {
            System.out.printf("%-20s", meta.getColumnName(i));
        }
        System.out.println();
        
        // Разделитель
        for (int i = 1; i <= columns; i++) {
            System.out.printf("%-20s", "--------------------");
        }
        System.out.println();
        
        // Данные
        while (rs.next() && rowCount < MAX_DISPLAY_ROWS) {
            for (int i = 1; i <= columns; i++) {
                String value = rs.getString(i);
                if (value != null && value.length() > 18) {
                    value = value.substring(0, 15) + "...";
                }
                System.out.printf("%-20s", value != null ? value : "null");
            }
            System.out.println();
            rowCount++;
        }
        
        if (rowCount >= MAX_DISPLAY_ROWS) {
            System.out.println("\n[Выведено " + MAX_DISPLAY_ROWS + " строк, остальные опущены]");
        }
        System.out.println("Всего строк: " + rowCount + "\n");
    }
}