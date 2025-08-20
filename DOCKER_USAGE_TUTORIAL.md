# AlphaGenome Proxy Docker Usage Tutorial

## What is Docker Deployment?

Docker deployment packages your AlphaGenome Proxy service into containers, making it easy to deploy on any cloud platform (Google Cloud, AWS, Azure, etc.) with consistent behavior.

## Why Use Docker?

1. **Consistency**: Same behavior across different environments
2. **Portability**: Easy to move between cloud providers
3. **Isolation**: Services run independently without conflicts
4. **Scalability**: Easy to scale up or down
5. **Professional**: Industry-standard deployment method

## Architecture Overview

```
User Request -> Nginx (Port 80) -> AlphaGenome API (Port 8000)
                      |
                Web Interface
```

- **Nginx**: Handles web requests and serves the HTML interface
- **AlphaGenome API**: Processes prediction requests
- **Docker**: Manages both services in containers

## Quick Start Guide

### Step 1: Local Testing

```bash
# 1. Navigate to project directory
cd alphagenome-main

# 2. Copy environment file
cp env.example .env

# 3. Edit environment file with your API key
nano .env
# Add: ALPHAGENOME_API_KEY=your_real_api_key

# 4. Build and start services
docker-compose up --build

# 5. Access the service
# Web interface: http://localhost
# API docs: http://localhost/api/docs
```

### Step 2: Google Cloud Deployment

#### Option A: Using Automated Script

```bash
# 1. Make script executable
chmod +x deploy-to-gcp.sh

# 2. Run deployment script
./deploy-to-gcp.sh

# 3. Follow the instructions provided
```

#### Option B: Manual Deployment

```bash
# 1. Create VM instance
gcloud compute instances create alphagenome-proxy \
    --zone=us-central1-a \
    --machine-type=e2-standard-2 \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --tags=http-server,https-server

# 2. SSH to instance
gcloud compute ssh alphagenome-proxy --zone=us-central1-a

# 3. Inside VM, clone and deploy
git clone <your-repo-url>
cd alphagenome-main
cp env.example .env
nano .env  # Add your API key
docker-compose up -d --build
```

## How Your Teacher's Team Will Use It

### 1. Web Interface Access

Once deployed, your teacher's team can:

```bash
# Access the web interface
http://YOUR_SERVER_IP/

# Features available:
- API Configuration tab: Enter API keys
- Prediction tab: Input variant data
- Results tab: View predictions and images
```

### 2. API Programming Access

Researchers can use the API directly:

```python
import requests

# Configure API
API_URL = "http://YOUR_SERVER_IP/api/predict_variant"
API_KEY = "their_api_key"

# Make prediction request
data = {
    "interval": {
        "chromosome": "chr22",
        "start": 35677410,
        "end": 36725986
    },
    "variant": {
        "chromosome": "chr22",
        "position": 36201698,
        "reference_bases": "A",
        "alternate_bases": "C"
    },
    "output_type": 4,
    "ontology_terms": [{"ontology_type": 2, "id": 1157}],
    "organism": 9606,
    "model_version": "v1"
}

# Send request
response = requests.post(
    API_URL,
    headers={"Authorization": f"Bearer {API_KEY}"},
    json=data
)

# Process results
if response.status_code == 200:
    result = response.json()
    print("Prediction successful!")
    print(f"Image data length: {len(result.get('plot_image', ''))}")
```

### 3. Command Line Access

```bash
# Using curl
curl -X POST http://YOUR_SERVER_IP/api/predict_variant \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "interval": {"chromosome": "chr22", "start": 35677410, "end": 36725986},
    "variant": {"chromosome": "chr22", "position": 36201698, "reference_bases": "A", "alternate_bases": "C"},
    "output_type": 4,
    "ontology_terms": [{"ontology_type": 2, "id": 1157}],
    "organism": 9606,
    "model_version": "v1"
  }'
```

## Service Management

### Check Service Status

```bash
# View running containers
docker-compose ps

# View logs
docker-compose logs -f

# Check health
curl http://YOUR_SERVER_IP/health
```

### Update Services

```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

### Restart Services

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart alphagenome-proxy
```

## Benefits for Your Teacher's Team

### 1. Easy Access
- Anyone can access from anywhere
- No need to install software locally
- Works on any device with a web browser

### 2. Team Collaboration
- Multiple researchers can use simultaneously
- Shared results and data
- Centralized management

### 3. Professional Presentation
- Looks like a professional service
- Suitable for academic publications
- Easy to demonstrate to others

### 4. Scalability
- Can handle multiple users
- Easy to add more resources if needed
- Cost-effective for research teams

## Troubleshooting

### Common Issues

1. **Service won't start**
   ```bash
   docker-compose logs alphagenome-proxy
   ```

2. **Can't access web interface**
   ```bash
   docker-compose ps
   curl http://localhost/health
   ```

3. **API errors**
   ```bash
   docker-compose logs -f alphagenome-proxy
   ```

### Getting Help

- Check logs: `docker-compose logs -f`
- Verify configuration: `docker-compose config`
- Test connectivity: `curl http://localhost/health`

## Summary

Docker deployment transforms your AlphaGenome Proxy from a local tool into a professional, accessible service that your teacher's team can use for:

- **Research**: Multiple researchers accessing simultaneously
- **Teaching**: Demonstrating to students
- **Collaboration**: Sharing with other research groups
- **Publication**: Providing accessible service in papers

The deployment is now ready for professional use!
