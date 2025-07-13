<?php
class GeoLocation {
    private static $api_endpoints = [
        'http://ip-api.com/json/',
        'https://ipapi.co/',
        'https://freegeoip.app/json/'
    ];
    
    public static function getLocationData($ip) {
        foreach (self::$api_endpoints as $endpoint) {
            $data = self::fetchFromEndpoint($endpoint, $ip);
            if ($data) return $data;
        }
        return ['country' => 'Unknown', 'city' => 'Unknown', 'region' => 'Unknown'];
    }
    
    private static function fetchFromEndpoint($endpoint, $ip) {
        $url = $endpoint . $ip;
        $context = stream_context_create(['http' => ['timeout' => 3]]);
        $response = @file_get_contents($url, false, $context);
        
        if ($response) {
            $data = json_decode($response, true);
            if ($data && isset($data['country'])) {
                return [
                    'country' => $data['country'] ?? 'Unknown',
                    'city' => $data['city'] ?? 'Unknown',
                    'region' => $data['region'] ?? $data['regionName'] ?? 'Unknown'
                ];
            }
        }
        return null;
    }
}
?>