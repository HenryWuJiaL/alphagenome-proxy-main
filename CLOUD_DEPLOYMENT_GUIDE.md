# AlphaGenome Communication Proxy - Cloud Deployment Guide

## Deployment Overview

This guide will help you deploy the AlphaGenome communication proxy to various cloud platforms:

- **AWS** - Using ECS + CloudFormation
- **Google Cloud** - Using Cloud Run
- **Azure** - Using Container Instances
- **Kubernetes** - Generic Kubernetes cluster

## Quick Deployment

### One-click Deployment Script

```bash
# Use automated deployment script
./scripts/deploy.sh aws          # AWS deployment
./scripts/deploy.sh gcp          # Google Cloud deployment
./scripts/deploy.sh azure        # Azure deployment
./scripts/deploy.sh kubernetes   # Kubernetes deployment
```

## AWS Deployment

### Prerequisites

```bash
# 1. Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# 2. Configure AWS credentials
aws configure
# AWS Access Key ID: your_access_key
# AWS Secret Access Key: your_secret_key
# Default region name: us-east-1
# Default output format: json

# 3. Verify configuration
aws sts get-caller-identity
```

### Method 1: Using CloudFormation (Recommended)

```bash
# 1. Set environment variables
export ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw
export AWS_REGION=us-east-1
export STACK_NAME=alphagenome-proxy

# 2. Create CloudFormation stack
aws cloudformation create-stack \
  --stack-name $STACK_NAME \
  --template-body file://deploy/aws/cloudformation.yaml \
  --parameters ParameterKey=ApiKey,ParameterValue=$ALPHAGENOME_API_KEY \
  --capabilities CAPABILITY_IAM \
  --region $AWS_REGION

# 3. Wait for deployment to complete
aws cloudformation wait stack-create-complete \
  --stack-name $STACK_NAME \
  --region $AWS_REGION

# 4. Get service URL
aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs[?OutputKey==`ServiceURL`].OutputValue' \
  --output text
```

### Method 2: Using ECS CLI

```bash
# 1. Build and push image to ECR
aws ecr create-repository --repository-name alphagenome-proxy --region $AWS_REGION
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker build -t alphagenome-proxy .
docker tag alphagenome-proxy:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/alphagenome-proxy:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/alphagenome-proxy:latest

# 2. Create ECS service
aws ecs create-service \
  --cluster alphagenome-cluster \
  --service-name alphagenome-proxy \
  --task-definition alphagenome-proxy:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-12345,subnet-67890],securityGroups=[sg-12345],assignPublicIp=ENABLED}"
```

### AWS Deployment Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │───►│   Application   │───►│   AlphaGenome   │
│   Load Balancer │    │   Load Balancer │    │      API        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### AWS CloudFormation Template

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'AlphaGenome Proxy Service on ECS Fargate'

Parameters:
  ApiKey:
    Type: String
    Description: AlphaGenome API Key
    NoEcho: true

Resources:
  # VPC and Networking
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: AlphaGenomeProxyVPC

  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      MapPublicIpOnLaunch: true

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.2.0/24
      AvailabilityZone: !Select [1, !GetAZs '']
      MapPublicIpOnLaunch: true

  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: AlphaGenomeProxyIGW

  AttachGateway:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref VPC
      InternetGatewayId: !Ref InternetGateway

  RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: AlphaGenomeProxyRouteTable

  DefaultRoute:
    Type: AWS::EC2::Route
    DependsOn: AttachGateway
    Properties:
      RouteTableId: !Ref RouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  SubnetRouteTableAssociation1:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnet1
      RouteTableId: !Ref RouteTable

  SubnetRouteTableAssociation2:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnet2
      RouteTableId: !Ref RouteTable

  # Security Groups
  ALBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for ALB
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0

  ECSSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for ECS tasks
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 8080
          ToPort: 8080
          SourceSecurityGroupId: !Ref ALBSecurityGroup

  # ECR Repository
  ECRRepository:
    Type: AWS::ECR::Repository
    Properties:
      RepositoryName: alphagenome-proxy
      ImageScanningConfiguration:
        ScanOnPush: true
      LifecyclePolicy:
        LifecyclePolicyText: |
          {
            "rules": [
              {
                "rulePriority": 1,
                "description": "Keep last 5 images",
                "selection": {
                  "tagStatus": "any",
                  "countType": "imageCountMoreThan",
                  "countNumber": 5
                },
                "action": {
                  "type": "expire"
                }
              }
            ]
          }

  # ECS Cluster
  ECSCluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: alphagenome-cluster
      CapacityProviders:
        - FARGATE
      DefaultCapacityProviderStrategy:
        - CapacityProvider: FARGATE
          Weight: 1

  # Task Definition
  TaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: alphagenome-proxy
      NetworkMode: awsvpc
      RequiresCompatibilities:
        - FARGATE
      Cpu: 256
      Memory: 512
      ExecutionRoleArn: !GetAtt ECSExecutionRole.Arn
      TaskRoleArn: !GetAtt ECSTaskRole.Arn
      ContainerDefinitions:
        - Name: alphagenome-proxy
          Image: !Sub "${AWS::AccountId}.dkr.ecr.${AWS::Region}.amazonaws.com/alphagenome-proxy:latest"
          PortMappings:
            - ContainerPort: 8080
              Protocol: tcp
          Environment:
            - Name: ALPHAGENOME_API_KEY
              Value: !Ref ApiKey
            - Name: JSON_SERVICE_BASE_URL
              Value: https://api.alphagenome.google.com
          LogConfiguration:
            LogDriver: awslogs
            Options:
              awslogs-group: !Ref CloudWatchLogsGroup
              awslogs-region: !Ref AWS::Region
              awslogs-stream-prefix: ecs

  # IAM Roles
  ECSExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: ecs-tasks.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

  ECSTaskRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: ecs-tasks.amazonaws.com
            Action: sts:AssumeRole

  # CloudWatch Logs
  CloudWatchLogsGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: /ecs/alphagenome-proxy
      RetentionInDays: 7

  # Application Load Balancer
  ALB:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: alphagenome-proxy-alb
      Scheme: internet-facing
      Type: application
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
      SecurityGroups:
        - !Ref ALBSecurityGroup

  ALBListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      LoadBalancerArn: !Ref ALB
      Port: 80
      Protocol: HTTP
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref ALBTargetGroup

  ALBTargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: alphagenome-proxy-tg
      Port: 8080
      Protocol: HTTP
      TargetType: ip
      VpcId: !Ref VPC
      HealthCheckPath: /health
      HealthCheckIntervalSeconds: 30
      HealthCheckTimeoutSeconds: 5
      HealthyThresholdCount: 2
      UnhealthyThresholdCount: 3

  # ECS Service
  ECSService:
    Type: AWS::ECS::Service
    DependsOn: ALBListener
    Properties:
      ServiceName: alphagenome-proxy
      Cluster: !Ref ECSCluster
      TaskDefinition: !Ref TaskDefinition
      DesiredCount: 2
      LaunchType: FARGATE
      NetworkConfiguration:
        AwsvpcConfiguration:
          AssignPublicIp: ENABLED
          SecurityGroups:
            - !Ref ECSSecurityGroup
          Subnets:
            - !Ref PublicSubnet1
            - !Ref PublicSubnet2
      LoadBalancers:
        - ContainerName: alphagenome-proxy
          ContainerPort: 8080
          TargetGroupArn: !Ref ALBTargetGroup

Outputs:
  ServiceURL:
    Description: URL of the AlphaGenome proxy service
    Value: !Sub "http://${ALB.DNSName}"
    Export:
      Name: !Sub "${AWS::StackName}-ServiceURL"

  ECRRepositoryURI:
    Description: ECR repository URI
    Value: !Sub "${AWS::AccountId}.dkr.ecr.${AWS::Region}.amazonaws.com/alphagenome-proxy"
    Export:
      Name: !Sub "${AWS::StackName}-ECRRepositoryURI"
```

## Google Cloud Deployment

### Prerequisites

```bash
# 1. Install Google Cloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init

# 2. Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable containerregistry.googleapis.com

# 3. Configure Docker authentication
gcloud auth configure-docker
```

### Method 1: Using Cloud Run (Recommended)

```bash
# 1. Set environment variables
export PROJECT_ID=$(gcloud config get-value project)
export ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw
export REGION=us-central1

# 2. Build and push Docker image
docker build -t gcr.io/$PROJECT_ID/alphagenome-proxy .
docker push gcr.io/$PROJECT_ID/alphagenome-proxy

# 3. Deploy to Cloud Run
gcloud run deploy alphagenome-proxy \
  --image gcr.io/$PROJECT_ID/alphagenome-proxy \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --set-env-vars JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com \
  --set-env-vars ALPHAGENOME_API_KEY=$ALPHAGENOME_API_KEY \
  --max-instances 10 \
  --memory 512Mi \
  --cpu 1

# 4. Get service URL
gcloud run services describe alphagenome-proxy \
  --region $REGION \
  --format 'value(status.url)'
```

### Method 2: Using GKE (Kubernetes)

```bash
# 1. Create GKE cluster
gcloud container clusters create alphagenome-cluster \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type e2-medium \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 10

# 2. Get cluster credentials
gcloud container clusters get-credentials alphagenome-cluster \
  --zone us-central1-a

# 3. Create namespace
kubectl create namespace alphagenome

# 4. Create secret for API key
kubectl create secret generic alphagenome-api-key \
  --from-literal=api-key=$ALPHAGENOME_API_KEY \
  --namespace alphagenome

# 5. Deploy application
kubectl apply -f deploy/kubernetes/ -n alphagenome

# 6. Check deployment
kubectl get pods -n alphagenome
kubectl get services -n alphagenome
```

### Google Cloud Deployment Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client        │───►│   Cloud Run     │───►│   AlphaGenome   │
│   Application   │    │   Service       │    │      API        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Kubernetes Deployment Files

```yaml
# deploy/kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alphagenome-proxy
  namespace: alphagenome
spec:
  replicas: 3
  selector:
    matchLabels:
      app: alphagenome-proxy
  template:
    metadata:
      labels:
        app: alphagenome-proxy
    spec:
      containers:
      - name: alphagenome-proxy
        image: gcr.io/PROJECT_ID/alphagenome-proxy:latest
        ports:
        - containerPort: 8080
        env:
        - name: JSON_SERVICE_BASE_URL
          value: "https://api.alphagenome.google.com"
        - name: ALPHAGENOME_API_KEY
          valueFrom:
            secretKeyRef:
              name: alphagenome-api-key
              key: api-key
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5

---
# deploy/kubernetes/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: alphagenome-proxy
  namespace: alphagenome
spec:
  selector:
    app: alphagenome-proxy
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer

---
# deploy/kubernetes/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: alphagenome-proxy-hpa
  namespace: alphagenome
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: alphagenome-proxy
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## Azure Deployment

### Prerequisites

```bash
# 1. Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# 2. Login to Azure
az login

# 3. Set subscription
az account set --subscription "your-subscription-id"
```

### Method 1: Using Container Instances

```bash
# 1. Create resource group
az group create --name alphagenome-rg --location eastus

# 2. Create container registry
az acr create --resource-group alphagenome-rg \
  --name alphagenomeregistry --sku Basic

# 3. Build and push image
az acr build --registry alphagenomeregistry \
  --image alphagenome-proxy:latest .

# 4. Deploy container instance
az container create \
  --resource-group alphagenome-rg \
  --name alphagenome-proxy \
  --image alphagenomeregistry.azurecr.io/alphagenome-proxy:latest \
  --dns-name-label alphagenome-proxy \
  --ports 8080 \
  --environment-variables \
    JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com \
    ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw

# 5. Get service URL
az container show \
  --resource-group alphagenome-rg \
  --name alphagenome-proxy \
  --query "ipAddress.fqdn" \
  --output tsv
```

### Method 2: Using AKS (Kubernetes)

```bash
# 1. Create AKS cluster
az aks create \
  --resource-group alphagenome-rg \
  --name alphagenome-cluster \
  --node-count 3 \
  --enable-addons monitoring \
  --generate-ssh-keys

# 2. Get cluster credentials
az aks get-credentials \
  --resource-group alphagenome-rg \
  --name alphagenome-cluster

# 3. Deploy using Kubernetes manifests
kubectl create namespace alphagenome
kubectl create secret generic alphagenome-api-key \
  --from-literal=api-key=$ALPHAGENOME_API_KEY \
  --namespace alphagenome
kubectl apply -f deploy/kubernetes/ -n alphagenome
```

## Kubernetes Deployment (Generic)

### Prerequisites

```bash
# 1. Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# 2. Configure kubectl for your cluster
kubectl config set-cluster your-cluster
kubectl config set-credentials your-user
kubectl config set-context your-context
kubectl config use-context your-context
```

### Deployment Steps

```bash
# 1. Create namespace
kubectl create namespace alphagenome

# 2. Create secret for API key
kubectl create secret generic alphagenome-api-key \
  --from-literal=api-key=$ALPHAGENOME_API_KEY \
  --namespace alphagenome

# 3. Deploy application
kubectl apply -f deploy/kubernetes/ -n alphagenome

# 4. Check deployment
kubectl get pods -n alphagenome
kubectl get services -n alphagenome
```

## Environment Variables

### Required Variables

```bash
# AlphaGenome API key
ALPHAGENOME_API_KEY=your-api-key-here

# JSON service base URL
JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com
```

### Optional Variables

```bash
# API key header name (default: Authorization)
API_KEY_HEADER=Authorization

# API key prefix (default: Bearer )
API_KEY_PREFIX=Bearer 

# Service port (default: 8080)
PORT=8080

# Log level (default: INFO)
LOG_LEVEL=INFO
```

## Testing Deployment

### Health Check

```bash
# Test health endpoint
curl https://your-service-url/health

# Expected response
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### gRPC Test

```python
import grpc
from src.alphagenome.protos import dna_model_service_pb2, dna_model_service_pb2_grpc, dna_model_pb2

# Connect to service
credentials = grpc.ssl_channel_credentials()
channel = grpc.secure_channel("your-service-url:443", credentials)
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)

# Test request
request = dna_model_service_pb2.PredictVariantRequest()
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

### CloudWatch (AWS)

```bash
# View logs
aws logs describe-log-groups --log-group-name-prefix /ecs/alphagenome-proxy

# Get log events
aws logs get-log-events \
  --log-group-name /ecs/alphagenome-proxy \
  --log-stream-name ecs/alphagenome-proxy/container-id
```

### Google Cloud Logging

```bash
# View logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=alphagenome-proxy"

# Create log sink
gcloud logging sinks create alphagenome-proxy-sink \
  storage.googleapis.com/projects/PROJECT_ID/buckets/alphagenome-logs \
  --log-filter="resource.type=cloud_run_revision AND resource.labels.service_name=alphagenome-proxy"
```

### Azure Monitor

```bash
# View logs
az monitor activity-log list \
  --resource-group alphagenome-rg \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z
```

## Cost Optimization

### AWS Cost Optimization

```bash
# Use Spot instances for ECS
aws ecs create-service \
  --cluster alphagenome-cluster \
  --service-name alphagenome-proxy \
  --task-definition alphagenome-proxy:1 \
  --capacity-provider-strategy capacityProvider=FARGATE_SPOT,weight=1 \
  --desired-count 2

# Set up auto-scaling
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/alphagenome-cluster/alphagenome-proxy \
  --min-capacity 1 \
  --max-capacity 10
```

### Google Cloud Cost Optimization

```bash
# Use preemptible instances for GKE
gcloud container clusters create alphagenome-cluster \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type e2-medium \
  --preemptible

# Set up auto-scaling
kubectl autoscale deployment alphagenome-proxy \
  --cpu-percent=70 \
  --min=1 \
  --max=10 \
  -n alphagenome
```

## Security Best Practices

### Network Security

```bash
# Use VPC for AWS
aws ec2 create-vpc --cidr-block 10.0.0.0/16

# Use private subnets
aws ec2 create-subnet \
  --vpc-id vpc-12345 \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a
```

### API Key Security

```bash
# Use AWS Secrets Manager
aws secretsmanager create-secret \
  --name alphagenome-api-key \
  --secret-string '{"api-key":"your-api-key"}'

# Use Google Secret Manager
gcloud secrets create alphagenome-api-key --data-file=-
echo "your-api-key" | gcloud secrets versions add alphagenome-api-key --data-file=-
```

### Container Security

```bash
# Scan Docker images
docker scan alphagenome-proxy:latest

# Use non-root user
USER 1000:1000

# Minimize attack surface
FROM python:3.11-slim
```

## Troubleshooting

### Common Issues

1. **Connection refused**
   - Check if service is running
   - Verify port configuration
   - Check firewall rules

2. **API key authentication failed**
   - Verify API key is correct
   - Check environment variables
   - Test API key with curl

3. **High latency**
   - Check network connectivity
   - Monitor resource usage
   - Consider auto-scaling

4. **Out of memory**
   - Increase memory limits
   - Optimize application
   - Add more instances

### Debug Commands

```bash
# Check service status
kubectl describe pod -n alphagenome
gcloud run services describe alphagenome-proxy --region=us-central1
aws ecs describe-services --cluster alphagenome-cluster --services alphagenome-proxy

# View logs
kubectl logs -n alphagenome -l app=alphagenome-proxy
gcloud logging read "resource.type=cloud_run_revision"
aws logs get-log-events --log-group-name /ecs/alphagenome-proxy

# Test connectivity
curl -v https://your-service-url/health
telnet your-service-url 443
```

## Performance Tuning

### Resource Optimization

```bash
# Optimize CPU and memory
--cpu 1 --memory 512Mi

# Use appropriate instance types
--machine-type e2-medium  # Google Cloud
--instance-type t3.medium # AWS
```

### Network Optimization

```bash
# Use HTTP/2
--http2

# Enable compression
--enable-compression

# Use CDN
--enable-cdn
```

### Application Optimization

```python
# Use connection pooling
import grpc
channel = grpc.secure_channel("service-url:443", 
                             grpc.ssl_channel_credentials(),
                             options=[('grpc.keepalive_time_ms', 30000)])

# Implement caching
import functools
@functools.lru_cache(maxsize=1000)
def cached_prediction(request):
    return stub.PredictVariant(request)
```

## Backup and Recovery

### Data Backup

```bash
# Backup configuration
kubectl get all -n alphagenome -o yaml > backup.yaml

# Backup secrets
kubectl get secrets -n alphagenome -o yaml > secrets-backup.yaml
```

### Disaster Recovery

```bash
# Restore from backup
kubectl apply -f backup.yaml
kubectl apply -f secrets-backup.yaml

# Cross-region deployment
gcloud run deploy alphagenome-proxy \
  --image gcr.io/PROJECT_ID/alphagenome-proxy \
  --region us-central1,us-east1,us-west1
```

## Conclusion

This comprehensive deployment guide covers all major cloud platforms and provides detailed instructions for deploying the AlphaGenome proxy service. Choose the platform that best fits your requirements and follow the step-by-step instructions for successful deployment.

For additional support and troubleshooting, refer to the platform-specific documentation and community resources. 