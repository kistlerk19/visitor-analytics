<?php
require_once 'config/database.php';
require_once 'includes/visitor_tracker.php';

// Track the current visitor
$tracker = new VisitorTracker($pdo);
$visitor_id = $tracker->trackVisitor();

// Get recent visitors for dashboard
$recent_visitors = $tracker->getRecentVisitors(50);
$visitor_stats = $tracker->getVisitorStats();
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Visitor Analytics Dashboard</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <div class="container">
        <header>
            <h1>Visitor Analytics Dashboard</h1>
            <p>Real-time visitor tracking and analytics</p>
        </header>

        <div class="stats-grid">
            <div class="stat-card">
                <h3>Total Visitors</h3>
                <p class="stat-number"><?php echo $visitor_stats['total']; ?></p>
            </div>
            <div class="stat-card">
                <h3>Today's Visitors</h3>
                <p class="stat-number"><?php echo $visitor_stats['today']; ?></p>
            </div>
            <div class="stat-card">
                <h3>Unique Countries</h3>
                <p class="stat-number"><?php echo $visitor_stats['countries']; ?></p>
            </div>
        </div>

        <div class="visitors-table">
            <h2>Recent Visitors</h2>
            <table>
                <thead>
                    <tr>
                        <th>IP Address</th>
                        <th>Location</th>
                        <th>Browser</th>
                        <th>OS</th>
                        <th>Device</th>
                        <th>Time</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($recent_visitors as $visitor): ?>
                    <tr>
                        <td><?php echo htmlspecialchars($visitor['ip_address']); ?></td>
                        <td><?php echo htmlspecialchars($visitor['city'] . ', ' . $visitor['country']); ?></td>
                        <td><?php echo htmlspecialchars($visitor['browser_name'] . ' ' . $visitor['browser_version']); ?></td>
                        <td><?php echo htmlspecialchars($visitor['operating_system']); ?></td>
                        <td><?php echo htmlspecialchars($visitor['device_type']); ?></td>
                        <td><?php echo date('M j, Y H:i', strtotime($visitor['visit_timestamp'])); ?></td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
    <script src="js/dashboard.js"></script>
</body>
</html>