# AlphaGenome Proxy Docker Deployment Guide

## Overview

This guide will help you deploy the AlphaGenome Proxy service on Google Cloud using Docker containerization technology to ensure service consistency and portability.

## Architecture

```
Internet -> Google Cloud VM -> Nginx (80/443) -> AlphaGenome API (8000)
                                    |
                              Web Interface (HTML)
```

- **Nginx**: Reverse proxy, provides Web interface and API routing
- **AlphaGenome API**: Core prediction service
- **Docker**: Containerized deployment, ensures environment consistency

## Quick Deployment

### 1. Prepare Environment

```bash
# Clone project
git clone <your-repo-url>
cd alphagenome-main

# Copy environment variables file
cp env.example .env

# Edit environment variables
nano .env
```

### 2. Configure Environment Variables

```bash
# .env file content
ALPHAGENOME_API_KEY=your_real_alphagenome_api_key
COMPOSE_PROJECT_NAME=alphagenome-proxy
```

### 3. Local Testing

```bash
# Build and start services
docker-compose up --build

# Check service status
docker-compose ps

# Test access
curl http://localhost/health
curl http://localhost/api/docs
```

## Google Cloud Deployment

### 1. Create VM Instance

```bash
# Use gcloud CLI to create instance
gcloud compute instances create alphagenome-proxy \
    --zone=us-central1-a \
    --machine-type=e2-standard-2 \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --tags=http-server,https-server \
    --metadata=startup-script='#! /bin/bash
        # Install Docker
        apt-get update
        apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Start Docker service
        systemctl start docker
        systemctl enable docker
        
        # Install git
        apt-get install -y git'
```

### 2. Configure Firewall

```bash
# Allow HTTP and HTTPS traffic
gcloud compute firewall-rules create allow-http \
    --allow tcp:80 \
    --target-tags=http-server \
    --description="Allow HTTP traffic"

gcloud compute firewall-rules create allow-https \
    --allow tcp:443 \
    --target-tags=https-server \
    --description="Allow HTTPS traffic"
```

### 3. Connect to VM

```bash
# SSH to instance
gcloud compute ssh alphagenome-proxy --zone=us-central1-a

# Execute the following commands inside VM
```

### 4. Deploy Application

```bash
# Inside VM
# Clone project
git clone <your-repo-url>
cd alphagenome-main

# Configure environment variables
cp env.example .env
nano .env  # Enter your API Key

# Build and start services
docker-compose up -d --build

# Check service status
docker-compose ps
docker-compose logs -f
```

### 5. Configure Domain and SSL (Optional)

```bash
# Install Certbot
apt-get install -y certbot python3-certbot-nginx

# Get SSL certificate
certbot --nginx -d your-domain.com

# Auto renewal
crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

## Service Management

### View Service Status

```bash
# View all containers
docker-compose ps

# View logs
docker-compose logs -f alphagenome-proxy
docker-compose logs -f nginx

# View resource usage
docker stats
```

### Restart Services

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart alphagenome-proxy
docker-compose restart nginx
```

### Update Services

```bash
# Pull latest code
git pull

# Rebuild and start
docker-compose down
docker-compose up -d --build
```

## Monitoring and Logs

### Health Checks

```bash
# API health check
curl http://YOUR_IP/health

# Service health check
docker-compose exec alphagenome-proxy curl -f http://localhost:8000/docs
```

### View Logs

```bash
# Real-time log viewing
docker-compose logs -f

# View specific service logs
docker-compose logs -f alphagenome-proxy
docker-compose logs -f nginx

# View container internal logs
docker-compose exec alphagenome-proxy tail -f /app/logs/app.log
```

## Security Configuration

### 1. Environment Variable Security

```bash
# Do not commit .env file to Git
echo ".env" >> .gitignore

# Use environment variables in production
export ALPHAGENOME_API_KEY="your_key"
docker-compose up -d
```

### 2. Network Security

```bash
# Only expose necessary ports
# Only map 80 and 443 in docker-compose.yml

# Use Google Cloud firewall to restrict access
gcloud compute firewall-rules create allow-specific-ips \
    --allow tcp:80,tcp:443 \
    --source-ranges=YOUR_IP_RANGE \
    --target-tags=http-server
```

### 3. Container Security

```bash
# Run with non-root user
# Already configured in Dockerfile

# Regularly update base images
docker-compose pull
docker-compose up -d --build
```

## Troubleshooting

### Common Issues

#### 1. Service Cannot Start

```bash
# Check logs
docker-compose logs alphagenome-proxy

# Check port usage
netstat -tlnp | grep :80
netstat -tlnp | grep :8000

# Check Docker status
systemctl status docker
```

#### 2. API Cannot Access

```bash
# Check container status
docker-compose ps

# Test internal connection
docker-compose exec nginx curl -f http://alphagenome-proxy:8000/docs

# Check network configuration
docker network ls
docker network inspect alphagenome-main_alphagenome-network
```

#### 3. Images Cannot Display

```bash
# Check AlphaGenome package installation
docker-compose exec alphagenome-proxy python -c "import alphagenome; print('OK')"

# Check matplotlib
docker-compose exec alphagenome-proxy python -c "import matplotlib; print('OK')"
```

## Performance Optimization

### 1. Resource Limits

```yaml
# Add to docker-compose.yml
services:
  alphagenome-proxy:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
```

### 2. Cache Configuration

```nginx
# Add cache to nginx.conf
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

## Access Methods

After deployment, users can access through:

### Web Interface
```
http://YOUR_VM_IP/
https://YOUR_DOMAIN/  # If SSL configured
```

### API Endpoints
```
http://YOUR_VM_IP/api/predict_variant
http://YOUR_VM_IP/api/score_variant
http://YOUR_VM_IP/api/docs
```

### Programming Calls
```python
import requests

response = requests.post(
    "http://YOUR_VM_IP/api/predict_variant",
    headers={"Authorization": "Bearer YOUR_API_KEY"},
    json={"your": "data"}
)
```

## Summary

Through Docker deployment, your AlphaGenome Proxy service now has:

- **Consistency**: Runs normally in any environment
- **Portability**: Easy migration to other cloud platforms
- **Scalability**: Supports horizontal scaling and load balancing
- **Easy Maintenance**: Simple update and rollback mechanisms
- **Professional Deployment**: Production-level stability and security

Now your teacher's team can easily deploy and use this service on Google Cloud!
