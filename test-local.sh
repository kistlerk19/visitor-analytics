#!/bin/bash

echo "Building and testing LAMP application locally..."

# Build the image
docker build -f disaster-recovery/Dockerfile.apache-rds -t lamp-test .

# Run with mock database (for testing without RDS)
docker run -d -p 8080:80 \
  -e DB_HOST=localhost \
  -e DB_NAME=visitor_analytics \
  -e DB_CREDENTIALS='{"username":"root","password":"test123"}' \
  --name lamp-test \
  lamp-test

echo "Waiting for container to start..."
sleep 5

echo "Testing endpoints:"
echo "Health check:"
curl -s http://localhost:8080/health.php | jq '.' || echo "Health check failed"

echo -e "\nMain page:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/

echo -e "\nAPI:"
curl -s http://localhost:8080/api.php?action=stats | jq '.' || echo "API failed"

echo -e "\nContainer logs:"
docker logs lamp-test

# Cleanup
docker stop lamp-test
docker rm lamp-test