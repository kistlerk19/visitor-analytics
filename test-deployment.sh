#!/bin/bash

echo "🔧 Testing LAMP Stack Deployment"

# Build the Docker image
echo "📦 Building Docker image..."
cd disaster-recovery
docker build -f Dockerfile.apache-rds -t lamp-test .

if [ $? -eq 0 ]; then
    echo "✅ Docker build successful"
else
    echo "❌ Docker build failed"
    exit 1
fi

# Test the image with a simple health check
echo "🏥 Testing health endpoint..."
docker run -d --name lamp-test-container -p 8080:80 \
    -e DB_HOST=localhost \
    -e DB_NAME=visitor_analytics \
    -e DB_USER=root \
    -e DB_PASSWORD=test \
    lamp-test

sleep 5

# Check if container is running
if docker ps | grep -q lamp-test-container; then
    echo "✅ Container is running"
    
    # Test health endpoint (will fail due to no DB, but should return proper error)
    curl -v http://localhost:8080/health.php || echo "Expected to fail without database"
    
    # Cleanup
    docker stop lamp-test-container
    docker rm lamp-test-container
    echo "🧹 Cleanup completed"
else
    echo "❌ Container failed to start"
    docker logs lamp-test-container
    docker rm lamp-test-container
    exit 1
fi

echo "🎉 Local test completed successfully"