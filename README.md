# AlphaGenome gRPC Proxy

A lightweight protocol translation proxy that converts gRPC requests to HTTP/JSON and vice versa for AlphaGenome services.

## Features

- Protocol conversion between gRPC and HTTP/JSON
- Streaming request/response support
- Binary data handling (images, audio, etc.)
- API key authentication
- Comprehensive error handling and logging
- Mock JSON service for testing

## Prerequisites

- Python 3.8+
- pip package manager

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/alphagenome-proxy.git
cd alphagenome-proxy
```

2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

## Quick Start

### 1. Start the Mock JSON Service

The mock service simulates the backend API responses:

```bash
uvicorn mock_json_service:app --reload --port 8000
```

This will start a FastAPI service on http://localhost:8000

### 2. Start the gRPC Proxy

In a new terminal:

```bash
python -c "from src.alphagenome.communication_proxy import serve; serve()"
```

This starts the gRPC proxy server on port 50051

### 3. Test the Setup

Run the comprehensive test:

```bash
python final_proxy_test.py
```

## Configuration

### Environment Variables

Set these environment variables before starting services:

```bash
export ALPHAGENOME_API_KEY="your_api_key_here"
export API_KEY_HEADER="Authorization"
export API_KEY_PREFIX="Bearer "
export JSON_SERVICE_BASE_URL="http://127.0.0.1:8000"
```

### API Key Configuration

The proxy supports flexible API key configuration:

- **Header Name**: Customize which HTTP header contains the API key
- **Prefix**: Add prefixes like "Bearer " or "API-Key "
- **Environment Variable**: Secure way to store sensitive keys

## Supported gRPC Methods

### 1. PredictSequence
Predicts genomic sequence characteristics.

```python
import grpc
from src.alphagenome.protos import dna_model_pb2, dna_model_service_pb2_grpc

channel = grpc.insecure_channel('localhost:50051')
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)

request = dna_model_pb2.PredictSequenceRequest()
request.sequence = "ATCGATCGATCG"
request.sequence_type = 1

responses = stub.PredictSequence(iter([request]))
for response in responses:
    print(f"Output type: {response.output.output_type}")
```

### 2. PredictInterval
Predicts characteristics for genomic intervals.

```python
request = dna_model_pb2.PredictIntervalRequest()
request.interval.chromosome = "chr1"
request.interval.start = 1000
request.interval.end = 2000

responses = stub.PredictInterval(iter([request]))
for response in responses:
    print(f"Output type: {response.output.output_type}")
```

### 3. PredictVariant
Predicts effects of genomic variants.

```python
request = dna_model_pb2.PredictVariantRequest()
request.interval.chromosome = "chr1"
request.interval.start = 1000
request.interval.end = 2000
request.variant.chromosome = "chr1"
request.variant.position = 1500
request.variant.reference_bases = "A"
request.variant.alternate_bases = "T"

responses = stub.PredictVariant(iter([request]))
for response in responses:
    print(f"Variant prediction: {response}")
```

### 4. ScoreInterval
Scores genomic intervals.

```python
request = dna_model_pb2.ScoreIntervalRequest()
request.interval.chromosome = "chr1"
request.interval.start = 1000
request.interval.end = 2000

responses = stub.ScoreInterval(iter([request]))
for response in responses:
    print(f"Interval score: {response}")
```

### 5. ScoreVariant
Scores genomic variants.

```python
request = dna_model_pb2.ScoreVariantRequest()
request.interval.chromosome = "chr1"
request.interval.start = 1000
request.interval.end = 2000
request.variant.chromosome = "chr1"
request.variant.position = 1500
request.variant.reference_bases = "A"
request.variant.alternate_bases = "T"

responses = stub.ScoreVariant(iter([request]))
for response in responses:
    print(f"Variant score: {response}")
```

### 6. ScoreIsmVariant
Scores ISM (In Silico Mutagenesis) variants.

```python
request = dna_model_pb2.ScoreIsmVariantRequest()
request.interval.chromosome = "chr1"
request.interval.start = 1000
request.interval.end = 2000
request.variant.chromosome = "chr1"
request.variant.position = 1500
request.variant.reference_bases = "A"
request.variant.alternate_bases = "T"

responses = stub.ScoreIsmVariant(iter([request]))
for response in responses:
    print(f"ISM variant score: {response}")
```

### 7. GetMetadata
Retrieves service metadata.

```python
request = dna_model_pb2.MetadataRequest()
request.model_name = "alphagenome_v1"

responses = stub.GetMetadata(request)
for response in responses:
    print(f"Metadata: {response}")
```

## Project Structure

```
src/alphagenome/
├── communication_proxy.py    # Main proxy implementation
├── alphagenome_types.py     # Type definitions
├── colab_utils.py           # Utility functions
├── tensor_utils.py          # Tensor operations
└── protos/                  # Protocol buffer definitions
    ├── dna_model_service.proto
    ├── dna_model.proto
    └── tensor.proto
```


## Deployment

### Production Considerations

1. **Security**: Use HTTPS for JSON service
2. **Authentication**: Implement proper API key validation
3. **Monitoring**: Add health checks and metrics
4. **Scaling**: Use load balancers for multiple proxy instances

### Docker Deployment

```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 50051
CMD ["python", "-c", "from src.alphagenome.communication_proxy import serve; serve()"]
```
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



