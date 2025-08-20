# Quick Start Guide - AlphaGenome Proxy Docker Deployment

## Prerequisites

- Docker and Docker Compose installed
- AlphaGenome API key
- Google Cloud account (for cloud deployment)

## Local Testing (5 minutes)

### Step 1: Setup
```bash
# Clone and navigate to project
cd alphagenome-main

# Configure environment
cp env.example .env
# Edit .env and add your API key
```

### Step 2: Test Locally
```bash
# Start services
docker-compose up --build

# Access web interface
open http://localhost

# Test API
curl http://localhost/api/docs
```

### Step 3: Verify
- Web interface loads correctly
- API documentation accessible
- Services running without errors

## Google Cloud Deployment (15 minutes)

### Option A: Automated Script
```bash
# Make script executable
chmod +x deploy-to-gcp.sh

# Run deployment
./deploy-to-gcp.sh

# Follow on-screen instructions
```

### Option B: Manual Steps
```bash
# 1. Create VM
gcloud compute instances create alphagenome-proxy \
    --zone=us-central1-a \
    --machine-type=e2-standard-2 \
    --image-family=debian-11 \
    --tags=http-server,https-server

# 2. SSH to VM
gcloud compute ssh alphagenome-proxy --zone=us-central1-a

# 3. Deploy app
git clone <your-repo>
cd alphagenome-main
cp env.example .env
# Edit .env with API key
docker-compose up -d --build
```

## Access Your Service

### Web Interface
```
http://YOUR_VM_IP/
```

### API Endpoints
```
http://YOUR_VM_IP/api/predict_variant
http://YOUR_VM_IP/api/score_variant
http://YOUR_VM_IP/api/docs
```

## Team Usage

### For Researchers
1. Access web interface
2. Enter API key
3. Input variant data
4. View predictions and images

### For Developers
```python
import requests

response = requests.post(
    "http://YOUR_VM_IP/api/predict_variant",
    headers={"Authorization": "Bearer YOUR_API_KEY"},
    json={"your": "data"}
)
```

## Management Commands

```bash
# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Update services
git pull && docker-compose up -d --build
```

## Troubleshooting

### Service Issues
```bash
# Check logs
docker-compose logs alphagenome-proxy

# Verify configuration
docker-compose config

# Test connectivity
curl http://localhost/health
```

### Common Problems
1. **Port conflicts**: Check if ports 80/8000 are free
2. **API key errors**: Verify .env file configuration
3. **Build failures**: Check Docker and requirements.txt

## Next Steps

1. **Test thoroughly** with your data
2. **Configure domain** (optional)
3. **Set up monitoring** and alerts
4. **Share with team** and collect feedback
5. **Optimize** based on usage patterns

## Support

- **Documentation**: See DOCKER_DEPLOYMENT_GUIDE.md
- **Tutorial**: See DOCKER_USAGE_TUTORIAL.md
- **Issues**: Check logs and configuration files

Your AlphaGenome Proxy is now ready for production use!
