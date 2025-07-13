<?php
header('Content-Type: application/json');

try {
    require_once 'config/database.php';
    
    // Test database connection
    $stmt = $pdo->query('SELECT 1');
    $db_status = $stmt ? 'healthy' : 'unhealthy';
    
    // Test table existence
    $stmt = $pdo->query('SHOW TABLES LIKE "visitors"');
    $table_exists = $stmt->rowCount() > 0;
    
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