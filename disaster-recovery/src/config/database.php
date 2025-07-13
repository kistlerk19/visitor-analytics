<?php
// Get database credentials from environment or Secrets Manager
$db_credentials_json = getenv('DB_CREDENTIALS');

if ($db_credentials_json) {
    // Parse credentials from Secrets Manager
    $credentials = json_decode($db_credentials_json, true);
    $host = $credentials['host'];
    $dbname = $credentials['dbname'];
    $username = $credentials['username'];
    $password = $credentials['password'];
} else {
    // Fallback to individual environment variables
    $host = getenv('DB_HOST') ?: 'localhost';
    $dbname = getenv('DB_NAME') ?: 'visitor_analytics';
    $username = getenv('DB_USER') ?: 'root';
    $password = getenv('DB_PASSWORD') ?: 'rootpassword';
}

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    die("Database connection failed: " . $e->getMessage());
}
?>