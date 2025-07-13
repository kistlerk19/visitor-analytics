<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once 'config/database.php';
require_once 'includes/visitor_tracker.php';

$tracker = new VisitorTracker($pdo);
$action = $_GET['action'] ?? 'stats';

try {
    switch ($action) {
        case 'stats':
            $stats = $tracker->getVisitorStats();
            echo json_encode(['success' => true, 'data' => $stats]);
            break;
            
        case 'recent':
            $limit = min((int)($_GET['limit'] ?? 10), 100);
            $visitors = $tracker->getRecentVisitors($limit);
            echo json_encode(['success' => true, 'data' => $visitors]);
            break;
            
        case 'track':
            $visitor_id = $tracker->trackVisitor();
            echo json_encode(['success' => true, 'visitor_id' => $visitor_id]);
            break;
            
        default:
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Invalid action']);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>