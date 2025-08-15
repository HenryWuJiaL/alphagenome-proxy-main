#!/bin/bash

# AlphaGenome Proxy Cloud Deployment Script
set -e

echo "=== AlphaGenome Proxy Cloud Deployment ==="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Error: Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check environment file
if [ ! -f .env ]; then
    echo "Warning: .env file not found. Creating from example..."
    cp env.example .env
    echo "Please edit .env file with your actual API key and configuration."
    echo "Then run this script again."
    exit 1
fi

# Load environment variables
source .env

# Check if API key is set
if [ -z "$ALPHAGENOME_API_KEY" ] || [ "$ALPHAGENOME_API_KEY" = "your_api_key_here" ]; then
    echo "Error: Please set ALPHAGENOME_API_KEY in .env file"
    exit 1
fi

echo "Building Docker image..."
docker-compose build

echo "Starting services..."
docker-compose up -d

echo "Waiting for services to start..."
sleep 10

# Check service health
echo "Checking service health..."
if curl -f http://localhost:8000/docs > /dev/null 2>&1; then
    echo "[SUCCESS] JSON Service is running on port 8000"
else
    echo "[FAILED] JSON Service failed to start"
    docker-compose logs
    exit 1
fi

# Check gRPC service
if nc -z localhost 50051 2>/dev/null; then
    echo "[SUCCESS] gRPC Proxy is running on port 50051"
else
    echo "[FAILED] gRPC Proxy failed to start"
    docker-compose logs
    exit 1
fi

echo ""
    echo "[SUCCESS] Deployment successful!"
echo "Services are running on:"
echo "  - JSON Service: http://localhost:8000"
echo "  - gRPC Proxy: localhost:50051"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop services: docker-compose down"
echo "To restart: docker-compose restart"
