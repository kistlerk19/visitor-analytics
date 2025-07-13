<?php
header('Content-Type: application/json');

try {
    require_once 'config/database.php';
    
    // Test database connection
    $stmt = $pdo->query('SELECT 1');
    $db_status = $stmt ? 'healthy' : 'unhealthy';
    
    // Test table existence and create if needed
    $stmt = $pdo->query('SHOW TABLES LIKE "visitors"');
    $table_exists = $stmt->rowCount() > 0;
    
    if (!$table_exists) {
        // Create the visitors table
        $create_table_sql = "
            CREATE TABLE visitors (
                id INT AUTO_INCREMENT PRIMARY KEY,
                ip_address VARCHAR(45) NOT NULL,
                country VARCHAR(100),
                city VARCHAR(100),
                region VARCHAR(100),
                browser_name VARCHAR(100),
                browser_version VARCHAR(50),
                operating_system VARCHAR(100),
                device_type VARCHAR(50),
                referrer_url TEXT,
                user_agent TEXT,
                visit_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_ip (ip_address),
                INDEX idx_timestamp (visit_timestamp)
            )
        ";
        $pdo->exec($create_table_sql);
        $table_exists = true;
    }
    
    $status = [
        'status' => ($db_status === 'healthy' && $table_exists) ? 'healthy' : 'unhealthy',
        'database' => $db_status,
        'table_exists' => $table_exists,
        'timestamp' => date('c')
    ];
    
    http_response_code($status['status'] === 'healthy' ? 200 : 503);
    echo json_encode($status);
    
} catch (Exception $e) {
    http_response_code(503);
    echo json_encode([
        'status' => 'unhealthy',
        'error' => $e->getMessage(),
        'timestamp' => date('c')
    ]);
}
?>