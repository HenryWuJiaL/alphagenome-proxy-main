# AlphaGenome Proxy Cloud Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying the AlphaGenome Communication Proxy to various cloud platforms. The proxy acts as a middleware layer that translates gRPC requests to HTTP/JSON and vice versa.

## Prerequisites

- Docker and Docker Compose installed
- Cloud platform account (AWS, GCP, Azure, etc.)
- AlphaGenome API key
- Basic knowledge of cloud services

## Quick Start with Docker

### Local Testing

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd alphagenome-proxy

# 2. Set up environment variables
cp env.example .env
# Edit .env file with your API key

# 3. Deploy locally
chmod +x deploy.sh
./deploy.sh
```

## Cloud Deployment Options

### Option 1: AWS (Amazon Web Services)

#### AWS EC2 Deployment

**Step 1: Launch EC2 Instance**
```bash
# Launch Ubuntu 20.04 LTS instance
# Instance type: t3.medium or larger
# Security Group: Allow ports 22 (SSH), 80 (HTTP), 443 (HTTPS), 50051 (gRPC)
```

**Step 2: Connect and Setup**
```bash
# SSH to your instance
ssh -i your-key.pem ubuntu@your-instance-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io docker-compose
sudo usermod -a -G docker $USER
newgrp docker

# Install additional tools
sudo apt install -y curl git
```

**Step 3: Deploy Application**
```bash
# Clone repository
git clone <your-repo-url>
cd alphagenome-proxy

# Configure environment
cp env.example .env
nano .env
# Set: ALPHAGENOME_API_KEY=your_actual_api_key

# Deploy
chmod +x deploy.sh
./deploy.sh
```

**Step 4: Configure Domain and SSL**
```bash
# Install Nginx as reverse proxy
sudo apt install -y nginx

# Configure Nginx
sudo nano /etc/nginx/sites-available/alphagenome-proxy
```

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /grpc {
        proxy_pass http://localhost:50051;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

```bash
# Enable site and restart
sudo ln -s /etc/nginx/sites-available/alphagenome-proxy /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Install SSL with Let's Encrypt
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

#### AWS ECS (Elastic Container Service)

**Step 1: Build and Push to ECR**
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS credentials
aws configure

# Create ECR repository
aws ecr create-repository --repository-name alphagenome-proxy

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build and push image
docker build -t alphagenome-proxy .
docker tag alphagenome-proxy:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/alphagenome-proxy:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/alphagenome-proxy:latest
```

**Step 2: Create ECS Task Definition**
```json
{
    "family": "alphagenome-proxy",
    "networkMode": "awsvpc",
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "512",
    "memory": "1024",
    "executionRoleArn": "arn:aws:iam::<account-id>:role/ecsTaskExecutionRole",
    "containerDefinitions": [
        {
            "name": "alphagenome-proxy",
            "image": "<account-id>.dkr.ecr.us-east-1.amazonaws.com/alphagenome-proxy:latest",
            "portMappings": [
                {"containerPort": 8000, "protocol": "tcp"},
                {"containerPort": 50051, "protocol": "tcp"}
            ],
            "environment": [
                {"name": "ALPHAGENOME_API_KEY", "value": "your_api_key"},
                {"name": "JSON_SERVICE_BASE_URL", "value": "http://localhost:8000"}
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/alphagenome-proxy",
                    "awslogs-region": "us-east-1",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
}
```

**Step 3: Create ECS Service**
```bash
# Create ECS cluster
aws ecs create-cluster --cluster-name alphagenome-cluster

# Create service
aws ecs create-service \
    --cluster alphagenome-cluster \
    --service-name alphagenome-proxy-service \
    --task-definition alphagenome-proxy:1 \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-12345],securityGroups=[sg-12345],assignPublicIp=ENABLED}"
```

### Option 2: Google Cloud Platform (GCP)

#### GCP Cloud Run

**Step 1: Setup GCP Project**
```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Initialize and authenticate
gcloud init
gcloud auth login
gcloud config set project <your-project-id>
```

**Step 2: Build and Deploy**
```bash
# Enable required APIs
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com

# Build and deploy
gcloud builds submit --tag gcr.io/<project-id>/alphagenome-proxy

# Deploy to Cloud Run
gcloud run deploy alphagenome-proxy \
    --image gcr.io/<project-id>/alphagenome-proxy \
    --platform managed \
    --region us-central1 \
    --allow-unauthenticated \
    --port 8000 \
    --set-env-vars ALPHAGENOME_API_KEY=<your-api-key> \
    --memory 1Gi \
    --cpu 1 \
    --max-instances 10
```

#### GKE (Google Kubernetes Engine)

**Step 1: Create GKE Cluster**
```bash
# Create cluster
gcloud container clusters create alphagenome-cluster \
    --zone us-central1-a \
    --num-nodes 3 \
    --machine-type e2-medium

# Get credentials
gcloud container clusters get-credentials alphagenome-cluster --zone us-central1-a
```

**Step 2: Deploy to GKE**
```bash
# Create namespace
kubectl create namespace alphagenome

# Create secret for API key
kubectl create secret generic alphagenome-secret \
    --from-literal=api-key=<your-api-key> \
    --namespace alphagenome

# Deploy application
kubectl apply -f k8s-deployment.yaml -n alphagenome

# Check status
kubectl get pods -n alphagenome
kubectl get services -n alphagenome
```

### Option 3: Azure

#### Azure Container Instances

**Step 1: Setup Azure CLI**
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login
az account set --subscription <subscription-id>
```

**Step 2: Create Container Registry and Deploy**
```bash
# Create resource group
az group create --name alphagenome-rg --location eastus

# Create container registry
az acr create --resource-group alphagenome-rg --name alphagenomeregistry --sku Basic

# Login to registry
az acr login --name alphagenomeregistry

# Build and push image
az acr build --registry alphagenomeregistry --image alphagenome-proxy .

# Create container instance
az container create \
    --resource-group alphagenome-rg \
    --name alphagenome-proxy \
    --image alphagenomeregistry.azurecr.io/alphagenome-proxy:latest \
    --ports 50051 8000 \
    --environment-variables ALPHAGENOME_API_KEY=<your-api-key> \
    --dns-name-label alphagenome-proxy \
    --location eastus
```

### Option 4: DigitalOcean

#### DigitalOcean App Platform

**Step 1: Prepare Repository**
```bash
# Ensure your repository has:
# - Dockerfile
# - .dockerignore
# - requirements.txt
# - All source code
```

**Step 2: Deploy via App Platform**
1. Go to DigitalOcean App Platform
2. Connect your GitHub repository
3. Select "Dockerfile" as build method
4. Set environment variables:
   - `ALPHAGENOME_API_KEY`: your_api_key
   - `JSON_SERVICE_BASE_URL`: http://localhost:8000
5. Configure resources (1GB RAM, 1 vCPU minimum)
6. Deploy

## Production Configuration

### Environment Variables
```bash
# Required
ALPHAGENOME_API_KEY=your_production_api_key

# Production settings
JSON_SERVICE_BASE_URL=https://your-backend-service.com
LOG_LEVEL=WARNING
GRPC_HOST=0.0.0.0
GRPC_PORT=50051
HTTP_PORT=8000

# Security
API_KEY_HEADER=Authorization
API_KEY_PREFIX=Bearer
```

### Security Best Practices

1. **API Key Management**
   - Use cloud-native secret management
   - Rotate keys regularly
   - Never commit keys to version control

2. **Network Security**
   - Configure security groups/firewall rules
   - Use VPC for private networking
   - Implement network segmentation

3. **SSL/TLS Configuration**
   - Use load balancer for SSL termination
   - Configure proper SSL certificates
   - Enable HTTP/2 for gRPC

4. **Monitoring and Logging**
   - Set up cloud monitoring
   - Configure log aggregation
   - Set up alerting for critical issues

### Scaling Configuration

1. **Horizontal Scaling**
   - Deploy multiple replicas
   - Use load balancer for distribution
   - Implement auto-scaling policies

2. **Resource Management**
   - Set appropriate CPU/memory limits
   - Monitor resource usage
   - Optimize based on actual usage patterns

3. **Performance Tuning**
   - Configure connection pooling
   - Optimize gRPC server settings
   - Implement caching strategies

## Troubleshooting

### Common Issues

1. **Service Not Starting**
   ```bash
   # Check logs
   docker-compose logs
   kubectl logs <pod-name> -n alphagenome
   
   # Check environment variables
   docker-compose exec alphagenome-proxy env
   ```

2. **Connection Issues**
   ```bash
   # Test connectivity
   curl http://localhost:8000/docs
   nc -z localhost 50051
   
   # Check firewall rules
   sudo ufw status
   ```

3. **API Key Issues**
   ```bash
   # Verify API key is set
   echo $ALPHAGENOME_API_KEY
   
   # Test API endpoint directly
   curl -H "Authorization: Bearer $ALPHAGENOME_API_KEY" \
        https://api.alphagenome.com/health
   ```

### Health Checks

```bash
# HTTP Service Health
curl -f http://your-domain.com/docs

# gRPC Service Health
grpc_health_probe -addr=your-domain.com:50051

# Docker Health
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"
```

## Maintenance

### Regular Tasks

1. **Security Updates**
   - Update base images monthly
   - Patch security vulnerabilities
   - Review access permissions

2. **Performance Monitoring**
   - Monitor response times
   - Track error rates
   - Analyze resource usage

3. **Backup and Recovery**
   - Backup configuration files
   - Document deployment procedures
   - Test recovery procedures

### Update Procedures

```bash
# Update application
git pull origin main
docker-compose build
docker-compose up -d

# Rollback if needed
docker-compose down
docker-compose up -d
```

## Support and Resources

- **Documentation**: Check project README.md
- **Issues**: Report on GitHub issues
- **Community**: Join relevant forums/discussions
- **Monitoring**: Use cloud-native monitoring tools

## Conclusion

This guide covers the essential steps for deploying the AlphaGenome Proxy to various cloud platforms. Choose the deployment method that best fits your infrastructure and requirements. Remember to follow security best practices and monitor your deployment for optimal performance.
