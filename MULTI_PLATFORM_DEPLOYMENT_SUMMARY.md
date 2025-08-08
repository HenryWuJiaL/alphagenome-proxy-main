# Multi-Platform Deployment Summary

## Overview

This project has been successfully configured to support deployment across multiple environments and platforms, including:

- **Cloud Platforms**: AWS, Google Cloud, Azure
- **Container Orchestration**: Kubernetes, Docker Swarm
- **Local Development**: Docker Compose, Local Python
- **Operating Systems**: Linux, macOS, Windows

## Deployment Options Comparison

| Platform | Use Case | Pros | Cons | Rating |
|----------|----------|------|------|--------|
| **Google Cloud Run** | Production, Student Projects | Free tier, Auto-scaling, Easy deployment | Limited customization | ⭐⭐⭐⭐⭐ |
| **AWS ECS Fargate** | Enterprise Production | High scalability, Advanced features | Complex setup, Higher cost | ⭐⭐⭐⭐ |
| **Azure Container Instances** | Azure Ecosystem | Integration with Azure services | Limited features | ⭐⭐⭐ |
| **Kubernetes** | Large-scale Production | Maximum flexibility, Advanced orchestration | Complex management | ⭐⭐⭐⭐ |
| **Local Docker** | Development Testing | Quick startup, Easy debugging | Requires local resources | ⭐ |

## Quick Start Guide

### 1. Google Cloud Run (Recommended for Students)

```bash
# Clone project
git clone https://github.com/your-username/alphagenome-proxy.git
cd alphagenome-proxy

# Set API key
export ALPHAGENOME_API_KEY=your_api_key_here

# Deploy
chmod +x student-deploy-gcp.sh
./student-deploy-gcp.sh
```

### 2. Local Docker Development

```bash
# Start services
docker-compose up -d

# Test service
curl http://localhost:8080/health
```

### 3. Kubernetes Deployment

```bash
# Create namespace
kubectl create namespace alphagenome

# Create secret
kubectl create secret generic alphagenome-api-key \
  --from-literal=api-key=$ALPHAGENOME_API_KEY \
  --namespace alphagenome

# Deploy
kubectl apply -f deploy/kubernetes/ -n alphagenome
```

## Platform-Specific Instructions

### Google Cloud Run

**Best for**: Students, small to medium projects, quick deployment

**Features**:
- Free tier: 2 million requests/month
- Auto-scaling based on demand
- HTTPS by default
- Easy integration with other Google services

**Deployment**:
```bash
# One-click deployment
./student-deploy-gcp.sh

# Manual deployment
gcloud run deploy alphagenome-proxy \
  --image gcr.io/PROJECT_ID/alphagenome-proxy \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars ALPHAGENOME_API_KEY=$ALPHAGENOME_API_KEY
```

### AWS ECS Fargate

**Best for**: Enterprise production, high availability requirements

**Features**:
- Serverless container management
- Advanced monitoring and logging
- Integration with AWS services
- High scalability

**Deployment**:
```bash
# Using CloudFormation
aws cloudformation create-stack \
  --stack-name alphagenome-proxy \
  --template-body file://deploy/aws/cloudformation.yaml \
  --parameters ParameterKey=ApiKey,ParameterValue=$ALPHAGENOME_API_KEY

# Using ECS CLI
aws ecs create-service \
  --cluster alphagenome-cluster \
  --service-name alphagenome-proxy \
  --task-definition alphagenome-proxy:1 \
  --desired-count 2
```

### Azure Container Instances

**Best for**: Azure ecosystem integration

**Features**:
- Serverless containers
- Pay-per-second billing
- Easy integration with Azure services
- Quick deployment

**Deployment**:
```bash
# Create container instance
az container create \
  --resource-group alphagenome-rg \
  --name alphagenome-proxy \
  --image alphagenomeregistry.azurecr.io/alphagenome-proxy:latest \
  --dns-name-label alphagenome-proxy \
  --ports 8080 \
  --environment-variables \
    ALPHAGENOME_API_KEY=$ALPHAGENOME_API_KEY
```

### Kubernetes

**Best for**: Large-scale production, maximum control

**Features**:
- Maximum flexibility
- Advanced orchestration
- Multi-cloud support
- Rich ecosystem

**Deployment**:
```bash
# Deploy to any Kubernetes cluster
kubectl apply -f deploy/kubernetes/ -n alphagenome

# Check deployment
kubectl get pods -n alphagenome
kubectl get services -n alphagenome
```

## Configuration Management

### Environment Variables

All platforms support the same environment variables:

```bash
# Required
ALPHAGENOME_API_KEY=your_api_key_here
JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com

# Optional
API_KEY_HEADER=Authorization
API_KEY_PREFIX=Bearer 
PORT=8080
LOG_LEVEL=INFO
```

### Platform-Specific Configuration

#### Google Cloud Run
```bash
# Use environment variables
--set-env-vars ALPHAGENOME_API_KEY=$ALPHAGENOME_API_KEY

# Use secrets (recommended for production)
gcloud secrets create alphagenome-api-key --data-file=-
echo $ALPHAGENOME_API_KEY | gcloud secrets versions add alphagenome-api-key --data-file=-
gcloud run deploy alphagenome-proxy --set-secrets ALPHAGENOME_API_KEY=alphagenome-api-key:latest
```

#### AWS ECS
```bash
# Use environment variables in task definition
{
  "name": "ALPHAGENOME_API_KEY",
  "value": "your_api_key_here"
}

# Use AWS Secrets Manager
{
  "name": "ALPHAGENOME_API_KEY",
  "valueFrom": "arn:aws:secretsmanager:region:account:secret:alphagenome-api-key"
}
```

#### Kubernetes
```bash
# Create secret
kubectl create secret generic alphagenome-api-key \
  --from-literal=api-key=$ALPHAGENOME_API_KEY \
  --namespace alphagenome

# Reference in deployment
env:
- name: ALPHAGENOME_API_KEY
  valueFrom:
    secretKeyRef:
      name: alphagenome-api-key
      key: api-key
```

## Testing and Validation

### Health Check

All deployments include health check endpoints:

```bash
# Test health
curl https://your-service-url/health

# Expected response
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### gRPC Testing

```python
import grpc
from src.alphagenome.protos import dna_model_service_pb2_grpc, dna_model_pb2

# Connect to service
credentials = grpc.ssl_channel_credentials()
channel = grpc.secure_channel("your-service-url:443", credentials)
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)

# Test request
request = dna_model_pb2.PredictVariantRequest()
request.interval.chromosome = "chr22"
request.interval.start = 35677410
request.interval.end = 36725986
request.variant.chromosome = "chr22"
request.variant.position = 36201698
request.variant.reference_bases = "A"
request.variant.alternate_bases = "C"
request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS

# Send request
response = stub.PredictVariant(request)
print(f"Response: {response}")
```

## Monitoring and Logging

### Google Cloud Run
```bash
# View logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=alphagenome-proxy"

# Monitor metrics
gcloud monitoring metrics list --filter="metric.type:run.googleapis.com"
```

### AWS ECS
```bash
# View logs
aws logs get-log-events \
  --log-group-name /ecs/alphagenome-proxy \
  --log-stream-name ecs/alphagenome-proxy/container-id

# Monitor metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=alphagenome-proxy
```

### Kubernetes
```bash
# View logs
kubectl logs -n alphagenome -l app=alphagenome-proxy

# Monitor resources
kubectl top pods -n alphagenome
kubectl describe pod -n alphagenome alphagenome-proxy-xxx
```

## Troubleshooting

### Common Issues

#### 1. API Key Error
```bash
# Check environment variable
echo $ALPHAGENOME_API_KEY

# Test API key
curl -H "Authorization: Bearer $ALPHAGENOME_API_KEY" \
  https://api.alphagenome.google.com/health
```

#### 2. Service Not Starting
```bash
# Check logs
docker logs alphagenome-proxy
kubectl logs -n alphagenome alphagenome-proxy-xxx
gcloud logging read "resource.type=cloud_run_revision"

# Check health
curl https://your-service-url/health
```

#### 3. Network Issues
```bash
# Test connectivity
telnet your-service-url 443
curl -v https://your-service-url/health

# Check DNS
nslookup your-service-url
```

### Platform-Specific Issues

#### Google Cloud Run
- **Cold start latency**: Normal for serverless, consider min-instances
- **Memory limits**: Increase memory allocation if needed
- **Concurrency limits**: Adjust max-instances based on load

#### AWS ECS
- **Task definition issues**: Check CPU/memory allocation
- **Service discovery**: Verify load balancer configuration
- **IAM permissions**: Ensure task role has required permissions

#### Kubernetes
- **Pod scheduling**: Check resource requests/limits
- **Service networking**: Verify service and ingress configuration
- **Persistent storage**: Check volume mounts if needed

## Performance Optimization

### Resource Allocation

```bash
# Google Cloud Run
--memory 512Mi --cpu 1 --max-instances 10

# AWS ECS
"cpu": 256, "memory": 512

# Kubernetes
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Auto-scaling

```bash
# Google Cloud Run (automatic)
--min-instances 1 --max-instances 10

# AWS ECS
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/alphagenome-cluster/alphagenome-proxy \
  --min-capacity 1 \
  --max-capacity 10

# Kubernetes
kubectl autoscale deployment alphagenome-proxy \
  --cpu-percent=70 \
  --min=1 \
  --max=10 \
  -n alphagenome
```

### Caching and Optimization

- Request result caching
- Connection pooling
- Response compression
- Load balancing

## Security Considerations

### Network Security

```bash
# Use HTTPS
--allow-unauthenticated  # Only for public services

# Use VPC (AWS/Azure)
--vpc-connector projects/PROJECT_ID/locations/REGION/connectors/CONNECTOR_NAME
```

### API Key Security

```bash
# Use secrets management
gcloud secrets create alphagenome-api-key --data-file=-
aws secretsmanager create-secret --name alphagenome-api-key
kubectl create secret generic alphagenome-api-key
```

### Container Security

```bash
# Scan images
docker scan alphagenome-proxy:latest

# Use non-root user
USER 1000:1000

# Minimize attack surface
FROM python:3.11-slim
```

## Cost Optimization

### Google Cloud Run
- Free tier: 2 million requests/month
- Pay only for actual usage
- No idle costs

### AWS ECS
- Use Spot instances for cost savings
- Right-size CPU/memory allocation
- Monitor and optimize resource usage

### Azure Container Instances
- Pay-per-second billing
- No idle costs
- Scale to zero when not in use

### Kubernetes
- Use resource quotas
- Implement horizontal pod autoscaling
- Monitor and optimize resource usage

## Migration Between Platforms

### Google Cloud Run to AWS ECS

1. **Export configuration**
   ```bash
   gcloud run services describe alphagenome-proxy --region=us-central1
   ```

2. **Create ECS task definition**
   ```bash
   aws ecs register-task-definition --cli-input-json file://task-definition.json
   ```

3. **Deploy to ECS**
   ```bash
   aws ecs create-service --cluster alphagenome-cluster --service-name alphagenome-proxy
   ```

### AWS ECS to Kubernetes

1. **Export ECS configuration**
   ```bash
   aws ecs describe-task-definition --task-definition alphagenome-proxy
   ```

2. **Convert to Kubernetes manifests**
   ```bash
   # Use tools like kompose or manual conversion
   kompose convert -f docker-compose.yml
   ```

3. **Deploy to Kubernetes**
   ```bash
   kubectl apply -f k8s/
   ```

## Conclusion

Through this deployment solution, you can choose the appropriate deployment method based on your specific requirements, achieving a complete deployment process from development to production.

Each platform offers unique advantages:
- **Google Cloud Run**: Best for students and quick deployment
- **AWS ECS**: Best for enterprise production
- **Azure Container Instances**: Best for Azure ecosystem
- **Kubernetes**: Best for maximum flexibility and control
- **Local Docker**: Best for development and testing

Choose the platform that best fits your use case, budget, and technical requirements. 