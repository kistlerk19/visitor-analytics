<?php
header('Content-Type: application/json');

try {
    // Basic health check - just verify PHP is working
    $status = [
        'status' => 'healthy',
        'php_version' => PHP_VERSION,
        'timestamp' => date('c')
    ];
    
    // Try database connection if possible
    if (file_exists('config/database.php')) {
        try {
            require_once 'config/database.php';
            $stmt = $pdo->query('SELECT 1');
            $status['database'] = 'connected';
        } catch (Exception $e) {
            $status['database'] = 'disconnected';
            $status['db_error'] = $e->getMessage();
        }
    }
    
    http_response_code(200);
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