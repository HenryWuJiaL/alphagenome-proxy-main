#!/bin/bash

# AlphaGenome Proxy Cloud Deployment Script
# Enhanced version for production deployment
set -e

echo "=== AlphaGenome Proxy Cloud Deployment ==="
echo "This script will deploy the service to your cloud environment"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running. Please start Docker first."
    exit 1
fi

print_status "Prerequisites check passed!"

# Check environment file
if [ ! -f .env ]; then
    print_warning ".env file not found. Creating from example..."
    cp env.example .env
    print_error "Please edit .env file with your actual API key and configuration."
    print_error "Then run this script again."
    exit 1
fi

# Load environment variables
source .env

# Check if API key is set
if [ -z "$ALPHAGENOME_API_KEY" ] || [ "$ALPHAGENOME_API_KEY" = "your_api_key_here" ]; then
    print_error "Please set ALPHAGENOME_API_KEY in .env file"
    print_error "Edit .env file and set your real AlphaGenome API key"
    exit 1
fi

print_status "Environment configuration verified!"

# Stop any existing containers
print_status "Stopping any existing containers..."
docker-compose down --remove-orphans 2>/dev/null || true

# Clean up old images (optional)
read -p "Do you want to clean up old Docker images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Cleaning up old images..."
    docker system prune -f
fi

# Build Docker image
print_status "Building Docker image..."
docker-compose build --no-cache

# Start services
print_status "Starting services..."
docker-compose up -d

# Wait for services to start
print_status "Waiting for services to start..."
sleep 15

# Check service health
print_status "Checking service health..."

# Wait for health check to pass
max_attempts=10
attempt=1
while [ $attempt -le $max_attempts ]; do
    if curl -f http://localhost/health > /dev/null 2>&1; then
        print_status "AlphaGenome Service is healthy!"
        break
    else
        print_warning "Health check attempt $attempt/$max_attempts failed, waiting..."
        sleep 10
        attempt=$((attempt + 1))
    fi
done

if [ $attempt -gt $max_attempts ]; then
    print_error "Service failed to become healthy after $max_attempts attempts"
    print_error "Container logs:"
    docker-compose logs
    exit 1
fi

# Check API endpoint
print_status "Checking API endpoints..."
if curl -f http://localhost/api/docs > /dev/null 2>&1; then
    print_status "API documentation is accessible"
else
    print_error "API documentation is not accessible"
    docker-compose logs
    exit 1
fi

# Check web interface
if curl -f http://localhost/ > /dev/null 2>&1; then
    print_status "Web interface is accessible"
else
    print_error "Web interface is not accessible"
    docker-compose logs
    exit 1
fi

# Display deployment information
echo ""
echo -e "${GREEN}=== DEPLOYMENT SUCCESSFUL! ===${NC}"
echo ""
echo "Services are running on:"
echo "  - Web Interface: http://localhost"
echo "  - API Service: http://localhost/api"
echo "  - API Documentation: http://localhost/api/docs"
echo "  - Health Check: http://localhost/health"
echo ""
echo "Container status:"
docker-compose ps
echo ""
echo "Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Stop services: docker-compose down"
echo "  - Restart services: docker-compose restart"
echo "  - Update services: docker-compose pull && docker-compose up -d"
echo ""
echo "For production deployment:"
echo "  - Configure SSL/TLS certificates"
echo "  - Set up proper domain name"
echo "  - Configure monitoring and logging"
echo "  - Set up backup strategies"
echo ""
print_status "Deployment completed successfully!"
