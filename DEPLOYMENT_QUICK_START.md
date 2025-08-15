# AlphaGenome Proxy - Quick Deployment Guide

## One-Click Deployment

### Prerequisites
- Docker and Docker Compose installed
- AlphaGenome API key
- Cloud platform account (optional, for cloud deployment)

### Quick Start

1. **Clone and Setup**
```bash
git clone <your-repo-url>
cd alphagenome-proxy
cp env.example .env
# Edit .env file with your API key
```

2. **Run Quick Deploy Script**
```bash
chmod +x quick-deploy.sh
./quick-deploy.sh
```

3. **Choose Deployment Option**
   - Option 1: Local deployment (Docker Compose)
   - Option 2: AWS ECR
   - Option 3: GCP Cloud Run
   - Option 4: Azure Container Instances

## Manual Deployment Steps

### Local Deployment
```bash
# Build and run
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs -f
```

### Cloud Deployment

#### AWS ECR
```bash
# Build and push
docker build -t alphagenome-proxy .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
docker tag alphagenome-proxy:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/alphagenome-proxy:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/alphagenome-proxy:latest
```

#### GCP Cloud Run
```bash
# Deploy
gcloud builds submit --tag gcr.io/<project-id>/alphagenome-proxy
gcloud run deploy alphagenome-proxy --image gcr.io/<project-id>/alphagenome-proxy --platform managed --region us-central1 --allow-unauthenticated
```

#### Azure Container Instances
```bash
# Deploy
az acr build --registry <registry-name> --image alphagenome-proxy .
az container create --resource-group <rg-name> --name alphagenome-proxy --image <registry-name>.azurecr.io/alphagenome-proxy:latest --ports 50051 8000
```

## Configuration

### Environment Variables
```bash
# Required
ALPHAGENOME_API_KEY=your_api_key_here

# Optional
JSON_SERVICE_BASE_URL=http://localhost:8000
API_KEY_HEADER=Authorization
API_KEY_PREFIX=Bearer
LOG_LEVEL=INFO
```

### Ports
- **8000**: HTTP/JSON service
- **50051**: gRPC proxy service

## Verification

### Health Check
```bash
# HTTP Service
curl http://localhost:8000/docs

# gRPC Service
nc -z localhost 50051
```

### Test Proxy
```bash
python final_proxy_test_clean.py
```

## Troubleshooting

### Common Issues
1. **Port already in use**: Check with `lsof -i :8000` or `lsof -i :50051`
2. **API key not set**: Ensure `.env` file exists and contains valid API key
3. **Docker not running**: Start Docker Desktop or Docker daemon
4. **Permission denied**: Run `chmod +x quick-deploy.sh`

### Logs
```bash
# Docker Compose logs
docker-compose logs -f

# Individual service logs
docker-compose logs alphagenome-proxy
```

## Additional Resources

- **Full Documentation**: `CLOUD_DEPLOYMENT_GUIDE.md`
- **Kubernetes**: `k8s-deployment.yaml`
- **Docker**: `Dockerfile` and `docker-compose.yml`
- **API Examples**: `api_inputs_clean.txt`

## Next Steps

After successful deployment:
1. Configure your domain and SSL certificate
2. Set up monitoring and logging
3. Configure auto-scaling
4. Set up backup and recovery procedures

---

**Need Help?** Check the full deployment guide or create an issue on GitHub.
