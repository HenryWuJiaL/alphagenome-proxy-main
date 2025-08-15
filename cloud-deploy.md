# Cloud Deployment Guide

## Supported Cloud Platforms

### 1. AWS (Amazon Web Services)

#### EC2 Deployment
```bash
# Launch EC2 instance (Ubuntu 20.04 LTS)
# Connect via SSH
sudo apt update
sudo apt install -y docker.io docker-compose
sudo usermod -a -G docker $USER

# Clone and deploy
git clone <your-repo>
cd <your-repo>
cp env.example .env
# Edit .env with your API key
chmod +x deploy.sh
./deploy.sh
```

#### ECS (Elastic Container Service)
```bash
# Build and push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
docker build -t alphagenome-proxy .
docker tag alphagenome-proxy:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/alphagenome-proxy:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/alphagenome-proxy:latest
```

### 2. Google Cloud Platform (GCP)

#### Cloud Run
```bash
# Build and deploy to Cloud Run
gcloud builds submit --tag gcr.io/<project-id>/alphagenome-proxy
gcloud run deploy alphagenome-proxy \
  --image gcr.io/<project-id>/alphagenome-proxy \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8000
```

#### GKE (Google Kubernetes Engine)
```bash
# Deploy to GKE
gcloud container clusters get-credentials <cluster-name> --zone <zone>
kubectl apply -f k8s-deployment.yaml
```

### 3. Azure

#### Azure Container Instances
```bash
# Build and push to Azure Container Registry
az acr build --registry <registry-name> --image alphagenome-proxy .
az container create \
  --resource-group <resource-group> \
  --name alphagenome-proxy \
  --image <registry-name>.azurecr.io/alphagenome-proxy:latest \
  --ports 50051 8000 \
  --environment-variables ALPHAGENOME_API_KEY=<your-api-key>
```

### 4. DigitalOcean

#### App Platform
```bash
# Deploy via App Platform
# 1. Connect your GitHub repository
# 2. Select Dockerfile as build method
# 3. Set environment variables
# 4. Deploy
```

## Environment Variables for Production

```bash
# Required
ALPHAGENOME_API_KEY=your_real_api_key

# Optional (with defaults)
JSON_SERVICE_BASE_URL=https://your-backend-service.com
API_KEY_HEADER=Authorization
API_KEY_PREFIX=Bearer
LOG_LEVEL=INFO

# Network (for production)
GRPC_HOST=0.0.0.0
GRPC_PORT=50051
HTTP_PORT=8000
```

## Security Considerations

1. **API Key Management**: Use cloud-native secret management (AWS Secrets Manager, GCP Secret Manager, Azure Key Vault)
2. **Network Security**: Configure security groups/firewall rules
3. **HTTPS**: Use load balancer or reverse proxy for SSL termination
4. **Monitoring**: Set up cloud monitoring and logging

## Scaling Considerations

1. **Horizontal Scaling**: Deploy multiple replicas behind load balancer
2. **Auto-scaling**: Use cloud auto-scaling groups or HPA in Kubernetes
3. **Resource Limits**: Set appropriate CPU/memory limits
4. **Health Checks**: Implement proper health check endpoints
