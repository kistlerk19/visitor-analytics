<?php
require_once 'config/database.php';
require_once 'includes/visitor_tracker.php';

$tracker = new VisitorTracker($pdo);

// Get IP detection info
$ip_headers = [
    'HTTP_X_FORWARDED_FOR',
    'HTTP_X_REAL_IP', 
    'HTTP_CLIENT_IP',
    'REMOTE_ADDR'
];

echo "<h2>IP Detection Debug</h2>";
foreach ($ip_headers as $header) {
    echo "$header: " . ($_SERVER[$header] ?? 'Not set') . "<br>";
}

// Get real public IP
$public_ip = @file_get_contents('https://api.ipify.org');
echo "<br>Your real public IP: $public_ip<br>";

// Test geolocation
if ($public_ip) {
    $location = $tracker->getLocationData($public_ip);
    echo "<br>Geolocation for $public_ip:<br>";
    print_r($location);
}

// Show what visitor tracker detects
echo "<br><h2>Visitor Tracker Detection</h2>";
$visitor_data = $tracker->collectVisitorData();
echo "<pre>";
print_r($visitor_data);
echo "</pre>";
?>