#!/bin/bash

# AlphaGenome Service Monitoring Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[HEADER]${NC} $1"
}

echo "=== AlphaGenome Service Monitor ==="
echo ""

# Check if services are running
print_header "Container Status"
if docker-compose ps | grep -q "Up"; then
    print_status "Services are running"
    docker-compose ps
else
    print_error "No services are running"
    exit 1
fi

echo ""

# Check health endpoints
print_header "Health Checks"

# Check main health endpoint
if curl -f http://localhost/health > /dev/null 2>&1; then
    print_status "Main health endpoint: OK"
else
    print_error "Main health endpoint: FAILED"
fi

# Check API health
if curl -f http://localhost/api/health > /dev/null 2>&1; then
    print_status "API health endpoint: OK"
else
    print_error "API health endpoint: FAILED"
fi

# Check web interface
if curl -f http://localhost/ > /dev/null 2>&1; then
    print_status "Web interface: OK"
else
    print_error "Web interface: FAILED"
fi

echo ""

# Check resource usage
print_header "Resource Usage"
echo "Container resource usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo ""

# Check logs for errors
print_header "Recent Logs (last 20 lines)"
echo "AlphaGenome API logs:"
docker-compose logs --tail=20 alphagenome-proxy

echo ""
echo "Nginx logs:"
docker-compose logs --tail=20 nginx

echo ""

# Check disk usage
print_header "Disk Usage"
echo "Docker disk usage:"
docker system df

echo ""

# Check network connectivity
print_header "Network Connectivity"
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    print_status "Internet connectivity: OK"
else
    print_warning "Internet connectivity: FAILED"
fi

# Check API response time
print_header "API Response Time"
start_time=$(date +%s.%N)
if curl -f http://localhost/api/health > /dev/null 2>&1; then
    end_time=$(date +%s.%N)
    response_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")
    print_status "API response time: ${response_time}s"
else
    print_error "API response time: FAILED"
fi

echo ""
print_status "Monitoring completed!"
