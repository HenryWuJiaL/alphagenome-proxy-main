# AlphaGenome Communication Proxy User Guide

## Overview

AlphaGenome Communication Proxy is a gRPC to JSON proxy service for connecting to the AlphaGenome API. It provides the following features:

- **gRPC Interface**: Provides standard gRPC service interface
- **JSON Conversion**: Automatically converts gRPC requests to JSON format
- **API Key Management**: Securely handles API keys
- **Multi-platform Deployment**: Supports Docker, AWS, Google Cloud, Kubernetes

## Quick Start

### 1. Requirements

- Python 3.10+
- Docker & Docker Compose
- API Key (obtain from [AlphaGenome](https://github.com/google-deepmind/alphagenome))

### 2. Installation and Startup

```bash
# Clone project
git clone <your-repo-url>
cd alphagenome-main

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/macOS
# or
venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt

# Configure API Key
export ALPHAGENOME_API_KEY=your_api_key_here

# Start service
docker-compose up -d
```

### 3. Verify Service

```bash
# Check service status
docker-compose ps

# Run tests
python -m pytest src/alphagenome/communication_proxy_test.py -v

# End-to-end test
python test_end_to_end.py
```

## Configuration

### Environment Variables

Create `.env` file or set environment variables:

```bash
# Base URL for JSON service
JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com

# AlphaGenome API Key
ALPHAGENOME_API_KEY=your_api_key_here

# API Key header name (optional, default is Authorization)
API_KEY_HEADER=Authorization

# API Key prefix (optional, default is "Bearer ")
API_KEY_PREFIX=Bearer
```

### Docker Compose Configuration

```yaml
version: '3.8'

services:
  alphagenome-proxy:
    build: .
    ports:
      - "50051:50051"
    environment:
      - JSON_SERVICE_BASE_URL=${JSON_SERVICE_BASE_URL:-https://api.alphagenome.google.com}
      - ALPHAGENOME_API_KEY=${ALPHAGENOME_API_KEY:-}
      - API_KEY_HEADER=${API_KEY_HEADER:-Authorization}
      - API_KEY_PREFIX=${API_KEY_PREFIX:-Bearer }
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
```

## API Usage

### gRPC Client Example

```python
import grpc
from alphagenome.protos import dna_model_pb2, dna_model_service_pb2_grpc

# Connect to proxy service
channel = grpc.insecure_channel('localhost:50051')
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)

# 1. Predict variant
request = dna_model_pb2.PredictVariantRequest()
request.interval.chromosome = "chr22"
request.interval.start = 35677410
request.interval.end = 36725986
request.variant.chromosome = "chr22"
request.variant.position = 36201698
request.variant.reference_bases = "A"
request.variant.alternate_bases = "C"
request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS

response = stub.PredictVariant(request)
print(f"Prediction result: {response}")

# 2. Score interval
request = dna_model_pb2.ScoreIntervalRequest()
request.interval.chromosome = "chr22"
request.interval.start = 35677410
request.interval.end = 35678410
request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS

response = stub.ScoreInterval(request)
print(f"Scoring result: {response}")

# 3. Streamed sequence prediction
request = dna_model_pb2.PredictSequenceRequest()
request.model_version = "test_model"
request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS
request.sequence = "ATCGATCG"

responses = stub.PredictSequence(iter([request]))
for response in responses:
    print(f"Sequence prediction: {response}")
    break
```

### Supported API Methods

| Method | Type | Description |
|------|------|------|
| `PredictVariant` | Non-streaming | Predict the impact of a genomic variant |
| `ScoreInterval` | Non-streaming | Score a genomic interval |
| `PredictSequence` | Streaming | Predict DNA sequence |
| `PredictInterval` | Streaming | Predict genomic interval |

## Docker Deployment

### Local Docker

```bash
# Build image
docker build -t alphagenome-proxy .

# Run container
docker run -d \
  --name alphagenome-proxy \
  -p 50051:50051 \
  -e ALPHAGENOME_API_KEY=your_api_key_here \
  -e JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com \
  alphagenome-proxy
```

### Docker Compose

```bash
# Start service
docker-compose up -d

# View logs
docker-compose logs -f alphagenome-proxy

# Stop service
docker-compose down
```

## Cloud Platform Deployment

### AWS Deployment

```bash
# Use CloudFormation
aws cloudformation create-stack \
  --stack-name alphagenome-proxy \
  --template-body file://deploy/aws/cloudformation.yaml \
  --parameters ParameterKey=ApiKey,ParameterValue=your_api_key_here

# Or use deployment script
./scripts/deploy.sh aws
```

### Google Cloud Deployment

```bash
# Use Cloud Run
gcloud run deploy alphagenome-proxy \
  --image gcr.io/your-project/alphagenome-proxy \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated

# Or use deployment script
./scripts/deploy.sh gcp
```

### Kubernetes Deployment

```bash
# Apply configuration
kubectl apply -f deploy/kubernetes/deployment.yaml

# Or use deployment script
./scripts/deploy.sh kubernetes
```

## Testing

### Unit Tests

```bash
# Run all unit tests
python -m pytest src/alphagenome/communication_proxy_test.py -v

# Run specific test
python -m pytest src/alphagenome/communication_proxy_test.py::CommunicationProxyTest::test_predict_variant_success -v
```

### End-to-end Tests

```bash
# Start test environment
docker-compose up -d

# Run end-to-end test
python test_end_to_end.py

# Test real API
python test_real_api.py
```

### Manual Testing

```bash
# Health check
curl -X GET http://localhost:8000/health

# Test gRPC connection
python -c "
import grpc
from alphagenome.protos import dna_model_service_pb2_grpc
channel = grpc.insecure_channel('localhost:50051')
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)
print('gRPC connection successful')
"
```

## Monitoring and Logging

### View Logs

```bash
# Docker logs
docker-compose logs -f alphagenome-proxy

# Application logs
tail -f logs/alphagenome-proxy.log
```

### Health Check

```bash
# Check service status
docker-compose ps

# Check health status
curl -X GET http://localhost:8000/health
```

### Performance Monitoring

```bash
# View resource usage
docker stats alphagenome-main2-alphagenome-proxy-1

# View network connections
netstat -an | grep 50051
```

## Troubleshooting

### Common Issues

#### 1. Service fails to start

```bash
# Check port usage
lsof -i :50051

# Check Docker status
docker-compose ps
docker-compose logs alphagenome-proxy
```

#### 2. API Key Error

```bash
# Verify environment variables
docker-compose exec alphagenome-proxy env | grep ALPHAGENOME_API_KEY

# Reset API Key
export ALPHAGENOME_API_KEY=your_new_api_key_here
docker-compose restart alphagenome-proxy
```

#### 3. Network Connection Issues

```bash
# Check network connection
curl -X GET https://api.alphagenome.google.com/health

# Check proxy configuration
docker-compose exec alphagenome-proxy env | grep JSON_SERVICE_BASE_URL
```

#### 4. gRPC Connection Failed

```bash
# Check gRPC service
grpcurl -plaintext localhost:50051 list

# Test gRPC call
grpcurl -plaintext -d '{}' localhost:50051 alphagenome.DnaModelService/PredictVariant
```

### Debug Mode

```bash
# Enable debug logging
export LOG_LEVEL=DEBUG
docker-compose restart alphagenome-proxy

# View detailed logs
docker-compose logs -f alphagenome-proxy
```

## Advanced Configuration

### Custom Request Headers

```python
# Customize request headers in code
def _get_headers():
    headers = {
        'Content-Type': 'application/json',
        'X-Custom-Header': 'custom-value'
    }
    
    if API_KEY:
        headers['Authorization'] = f"Bearer {API_KEY}"
    
    return headers
```

### Load Balancing

```yaml
# Use multiple proxy instances
version: '3.8'
services:
  alphagenome-proxy-1:
    build: .
    ports:
      - "50051:50051"
    environment:
      - ALPHAGENOME_API_KEY=${ALPHAGENOME_API_KEY}
  
  alphagenome-proxy-2:
    build: .
    ports:
      - "50052:50051"
    environment:
      - ALPHAGENOME_API_KEY=${ALPHAGENOME_API_KEY}
```

### Cache Configuration

```python
# Add cache support
import redis
import json

redis_client = redis.Redis(host='localhost', port=6379, db=0)

def get_cached_response(request_key):
    cached = redis_client.get(request_key)
    if cached:
        return json.loads(cached)
    return None

def cache_response(request_key, response):
    redis_client.setex(request_key, 3600, json.dumps(response))
```

## Security Best Practices

### API Key Security

```bash
# Use environment variables instead of hardcoding
export ALPHAGENOME_API_KEY=your_api_key_here

# Use key management service
# AWS Secrets Manager
aws secretsmanager get-secret-value --secret-id alphagenome-api-key

# Google Secret Manager
gcloud secrets versions access latest --secret="alphagenome-api-key"
```

### Network Security

```yaml
# Restrict network access
services:
  alphagenome-proxy:
    networks:
      - internal
    ports:
      - "127.0.0.1:50051:50051"  # Only allow local access

networks:
  internal:
    driver: bridge
```

### Log Security

```python
# Avoid logging sensitive information
import logging

def log_request(request_dict):
    # Remove sensitive fields
    safe_request = request_dict.copy()
    if 'api_key' in safe_request:
        safe_request['api_key'] = '***'
    
    logging.info(f"Request: {safe_request}")
```

## Support and Feedback

### Get Help

- **Documentation**: Check the `docs/` directory
- **Examples**: Check Jupyter notebooks in the `colabs/` directory
- **Testing**: Run the test suite to verify functionality

### Report Issues

1. Check log files
2. Run diagnostic tests
3. Collect environment information
4. Submit detailed issue reports

### Contributing

1. Fork the project
2. Create a feature branch
3. Commit changes
4. Create a Pull Request

---

## License

This project is licensed under the Apache 2.0 License. See [LICENSE](LICENSE) file.

## Acknowledgments

Thank you to Google DeepMind for providing the AlphaGenome API and the open-source community for support. 