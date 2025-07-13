#!/bin/bash

set -e

# Database Initialization Script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Initializing RDS Database ==="

cd "$PROJECT_DIR"

# Get database credentials from Secrets Manager
SECRET_ARN=$(terraform output -raw primary_secrets_arn 2>/dev/null || echo "")
DB_ENDPOINT=$(terraform output -raw primary_db_endpoint)

if [ -n "$SECRET_ARN" ]; then
    echo "Getting credentials from Secrets Manager..."
    CREDENTIALS=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --query 'SecretString' --output text)
    DB_PASSWORD=$(echo "$CREDENTIALS" | jq -r '.password')
    DB_USER=$(echo "$CREDENTIALS" | jq -r '.username')
else
    echo "Using default credentials..."
    DB_USER="root"
    DB_PASSWORD="rootpassword"
fi

echo "Initializing database schema..."
mysql -h "$DB_ENDPOINT" -u "$DB_USER" -p"$DB_PASSWORD" << 'EOF'
CREATE DATABASE IF NOT EXISTS visitor_analytics;
USE visitor_analytics;

CREATE TABLE IF NOT EXISTS visitors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ip_address VARCHAR(45) NOT NULL,
    user_agent TEXT,
    visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    country VARCHAR(100),
    city VARCHAR(100),
    browser VARCHAR(100),
    os VARCHAR(100),
    device VARCHAR(100),
    INDEX idx_visit_time (visit_time),
    INDEX idx_ip_address (ip_address)
);

-- Insert sample data for testing
INSERT IGNORE INTO visitors (ip_address, user_agent, country, city, browser, os, device) VALUES
('192.168.1.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', 'United States', 'New York', 'Chrome', 'Windows', 'Desktop'),
('10.0.0.1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36', 'United States', 'San Francisco', 'Chrome', 'macOS', 'Desktop');

SELECT COUNT(*) as total_visitors FROM visitors;
EOF

echo "✅ Database initialization completed"
echo "✅ Sample data inserted"