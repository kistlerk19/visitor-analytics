<?php
require_once 'geolocation.php';

class VisitorTracker {
    private $pdo;
    
    public function __construct($pdo) {
        $this->pdo = $pdo;
        $this->ensureTableExists();
    }
    
    private function ensureTableExists() {
        $sql = "CREATE TABLE IF NOT EXISTS visitors (
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
        )";
        $this->pdo->exec($sql);
    }
    
    public function trackVisitor() {
        $visitor_data = $this->collectVisitorData();
        
        $stmt = $this->pdo->prepare("
            INSERT INTO visitors (
                ip_address, country, city, region, browser_name, 
                browser_version, operating_system, device_type, 
                referrer_url, user_agent
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $visitor_data['ip'],
            $visitor_data['country'],
            $visitor_data['city'],
            $visitor_data['region'],
            $visitor_data['browser_name'],
            $visitor_data['browser_version'],
            $visitor_data['os'],
            $visitor_data['device_type'],
            $visitor_data['referrer'],
            $visitor_data['user_agent']
        ]);
        
        return $this->pdo->lastInsertId();
    }
    
    public function collectVisitorData() {
        $ip = $this->getClientIP();
        $user_agent = $_SERVER['HTTP_USER_AGENT'] ?? '';
        $location = $this->getLocationData($ip);
        $browser_info = $this->parseBrowserInfo($user_agent);
        
        return [
            'ip' => $ip,
            'country' => $location['country'] ?? 'Unknown',
            'city' => $location['city'] ?? 'Unknown',
            'region' => $location['region'] ?? 'Unknown',
            'browser_name' => $browser_info['name'],
            'browser_version' => $browser_info['version'],
            'os' => $this->getOperatingSystem($user_agent),
            'device_type' => $this->getDeviceType($user_agent),
            'referrer' => $_SERVER['HTTP_REFERER'] ?? '',
            'user_agent' => $user_agent
        ];
    }
    
    private function getClientIP() {
        $ip_headers = [
            'HTTP_X_FORWARDED_FOR',
            'HTTP_X_REAL_IP',
            'HTTP_CLIENT_IP',
            'REMOTE_ADDR'
        ];
        
        foreach ($ip_headers as $header) {
            if (!empty($_SERVER[$header])) {
                $ip = trim(explode(',', $_SERVER[$header])[0]);
                if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)) {
                    return $ip;
                }
            }
        }
        
        $remote_ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
        
        // For local testing, get real public IP
        if (in_array($remote_ip, ['127.0.0.1', '::1', '172.17.0.1', '172.18.0.1']) || 
            preg_match('/^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)/', $remote_ip)) {
            $public_ip = @file_get_contents('https://api.ipify.org', false, stream_context_create(['http' => ['timeout' => 3]]));
            if ($public_ip && filter_var($public_ip, FILTER_VALIDATE_IP)) {
                return $public_ip;
            }
        }
        
        return $remote_ip;
    }
    
    public function getLocationData($ip) {
        return GeoLocation::getLocationData($ip);
    }
    
    private function parseBrowserInfo($user_agent) {
        $browsers = [
            'Chrome' => '/Chrome\/([0-9.]+)/',
            'Firefox' => '/Firefox\/([0-9.]+)/',
            'Safari' => '/Safari\/([0-9.]+)/',
            'Edge' => '/Edge\/([0-9.]+)/',
            'Opera' => '/Opera\/([0-9.]+)/'
        ];
        
        foreach ($browsers as $browser => $pattern) {
            if (preg_match($pattern, $user_agent, $matches)) {
                return ['name' => $browser, 'version' => $matches[1]];
            }
        }
        
        return ['name' => 'Unknown', 'version' => ''];
    }
    
    private function getOperatingSystem($user_agent) {
        $os_patterns = [
            'Windows NT 10.0' => 'Windows 10',
            'Windows NT 6.3' => 'Windows 8.1',
            'Windows NT 6.2' => 'Windows 8',
            'Windows NT 6.1' => 'Windows 7',
            'Macintosh' => 'macOS',
            'Linux' => 'Linux',
            'Android' => 'Android',
            'iPhone' => 'iOS',
            'iPad' => 'iPadOS'
        ];
        
        foreach ($os_patterns as $pattern => $os) {
            if (strpos($user_agent, $pattern) !== false) {
                return $os;
            }
        }
        
        return 'Unknown';
    }
    
    private function getDeviceType($user_agent) {
        if (preg_match('/Mobile|Android|iPhone|iPad/', $user_agent)) {
            return 'Mobile';
        } elseif (preg_match('/Tablet|iPad/', $user_agent)) {
            return 'Tablet';
        }
        return 'Desktop';
    }
    
    public function getRecentVisitors($limit = 50) {
        $limit = (int)$limit;
        $stmt = $this->pdo->prepare("
            SELECT * FROM visitors 
            ORDER BY visit_timestamp DESC 
            LIMIT $limit
        ");
        $stmt->execute();
        return $stmt->fetchAll();
    }
    
    public function getVisitorStats() {
        $stats = [];
        
        // Total visitors
        $stmt = $this->pdo->query("SELECT COUNT(*) as total FROM visitors");
        $stats['total'] = $stmt->fetch()['total'];
        
        // Today's visitors
        $stmt = $this->pdo->query("
            SELECT COUNT(*) as today FROM visitors 
            WHERE DATE(visit_timestamp) = CURDATE()
        ");
        $stats['today'] = $stmt->fetch()['today'];
        
        // Unique countries
        $stmt = $this->pdo->query("
            SELECT COUNT(DISTINCT country) as countries FROM visitors 
            WHERE country != 'Unknown'
        ");
        $stats['countries'] = $stmt->fetch()['countries'];
        
        return $stats;
    }
}
?>