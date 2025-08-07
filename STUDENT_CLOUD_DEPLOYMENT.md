# Student Free Cloud Deployment Guide

## Free Cloud Platform Comparison

| Platform | Free Tier | Application Difficulty | Recommendation |
|----------|-----------|----------------------|----------------|
| **Google Cloud** | $300 + Always Free | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **AWS** | 12-month free tier | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Azure** | $100 student credit | ⭐⭐ | ⭐⭐⭐⭐ |
| **Oracle Cloud** | Always free | ⭐⭐⭐ | ⭐⭐⭐ |

## Google Cloud Deployment (Recommended)

### Step 1: Register Student Account

1. **Visit Google Cloud Student Page**
   ```
   https://cloud.google.com/edu
   ```

2. **Register with Educational Email**
   - Use your school email (e.g., student@university.edu)
   - Verify student identity

3. **Get Free Credits**
   - $300 free credits (90 days)
   - Always Free tier (permanent)

### Step 2: Create Project

```bash
# Install Google Cloud SDK
# macOS
brew install google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Initialize project
gcloud init

# Create new project
gcloud projects create alphagenome-student-project

# Set project
gcloud config set project alphagenome-student-project

# Enable required services
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### Step 3: Deploy Application

```bash
# Set environment variables
export PROJECT_ID=alphagenome-student-project
export ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw

# Build Docker image
docker build -t gcr.io/$PROJECT_ID/alphagenome-proxy .

# Push image to Google Container Registry
docker push gcr.io/$PROJECT_ID/alphagenome-proxy

# Deploy to Cloud Run
gcloud run deploy alphagenome-proxy \
  --image gcr.io/$PROJECT_ID/alphagenome-proxy \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars ALPHAGENOME_API_KEY=$ALPHAGENOME_API_KEY \
  --set-env-vars JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com \
  --port 50051 \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 5

# Get service URL
gcloud run services describe alphagenome-proxy \
  --region us-central1 \
  --format 'value(status.url)'
```

### Step 4: Test Service

```bash
# Test health check
curl -X GET https://your-service-url/health

# Test gRPC connection
python -c "
import grpc
from alphagenome.protos import dna_model_service_pb2_grpc
channel = grpc.insecure_channel('your-service-url:50051')
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)
print('Connection successful')
"
```

## AWS Free Deployment

### Step 1: Register AWS Free Account

1. **Visit AWS Free Tier**
   ```
   https://aws.amazon.com/free/
   ```

2. **Register Account**
   - Requires credit card verification (no charge)
   - Get 12-month free tier

### Step 2: Deploy to ECS

```bash
# Install AWS CLI
# macOS
brew install awscli

# Configure AWS
aws configure

# Create ECR repository
aws ecr create-repository --repository-name alphagenome-proxy

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build and push image
docker build -t alphagenome-proxy .
docker tag alphagenome-proxy:latest $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/alphagenome-proxy:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/alphagenome-proxy:latest

# Use CloudFormation to deploy
aws cloudformation create-stack \
  --stack-name alphagenome-student \
  --template-body file://deploy/aws/cloudformation.yaml \
  --parameters ParameterKey=ApiKey,ParameterValue=$ALPHAGENOME_API_KEY \
  --capabilities CAPABILITY_IAM
```

## Oracle Cloud Permanent Free

### Step 1: Register Oracle Cloud

1. **Visit Oracle Cloud Free Tier**
   ```
   https://www.oracle.com/cloud/free/
   ```

2. **Register Account**
   - Requires credit card verification
   - Get permanent free tier

### Step 2: Create VM Instance

```bash
# Create VM instance
# Select Oracle Linux
# Configuration: 1 OCPU, 6GB RAM

# Connect to instance
ssh opc@your-instance-ip

# Install Docker
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker opc

# Re-login
exit
ssh opc@your-instance-ip

# Deploy application
docker run -d \
  --name alphagenome-proxy \
  -p 50051:50051 \
  -e ALPHAGENOME_API_KEY=$ALPHAGENOME_API_KEY \
  -e JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com \
  alphagenome-proxy:latest
```

## Cost Comparison

### Google Cloud Run
- **Free Tier**: 2000000 requests per month
- **Over-usage Fee**: $0.0000024/request
- **Student Discount**: $300 free credits
- **Total Cost**: Almost free

### AWS ECS
- **Free Tier**: 400000 seconds Fargate
- **Over-usage Fee**: $0.04048/vCPU-hour
- **Student Discount**: 12-month free
- **Total Cost**: Free (within 12 months)

### Oracle Cloud
- **Free Tier**: Permanent free
- **Resources**: 2 VM instances
- **Student Discount**: No additional discount
- **Total Cost**: Permanent free

## Student Exclusive Discounts

### 1. GitHub Student Developer Pack
```
https://education.github.com/pack
```
- Multiple cloud platform free tiers
- Free development tools
- Learning resources

### 2. Microsoft Azure for Students
```
https://azure.microsoft.com/zh-cn/free/students/
```
- $100 free credit
- No time limit
- 40+ free services

### 3. Google Cloud for Students
```
https://cloud.google.com/edu
```
- Additional learning resources
- Certification exam discounts
- Community support

## One-Click Deployment Script

### Google Cloud One-Click Deployment

```bash
#!/bin/bash
# student-deploy-gcp.sh

set -e

echo "🎓 Student Google Cloud Deployment Script"

# Check dependencies
if ! command -v gcloud &> /dev/null; then
    echo "❌ Please install Google Cloud SDK first"
    exit 1
fi

# Set variables
export PROJECT_ID=alphagenome-student-$(date +%s)
export ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw

echo "📦 Creating project: $PROJECT_ID"
gcloud projects create $PROJECT_ID
gcloud config set project $PROJECT_ID

echo "�� Enabling services"
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

echo "🐳 Building image"
docker build -t gcr.io/$PROJECT_ID/alphagenome-proxy .
docker push gcr.io/$PROJECT_ID/alphagenome-proxy

echo "🚀 Deploying to Cloud Run"
gcloud run deploy alphagenome-proxy \
  --image gcr.io/$PROJECT_ID/alphagenome-proxy \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars ALPHAGENOME_API_KEY=$ALPHAGENOME_API_KEY \
  --port 50051

echo "✅ Deployment complete!"
echo "🌐 Service URL:"
gcloud run services describe alphagenome-proxy \
  --region us-central1 \
  --format 'value(status.url)'
```

### Usage

```bash
# Give script execution permission
chmod +x student-deploy-gcp.sh

# Run deployment
./student-deploy-gcp.sh
```

## Learning Resources

### 1. Cloud Platform Learning
- **Google Cloud**: https://cloud.google.com/learn
- **AWS**: https://aws.amazon.com/training/
- **Azure**: https://docs.microsoft.com/learn/

### 2. Containerization Learning
- **Docker**: https://docs.docker.com/get-started/
- **Kubernetes**: https://kubernetes.io/docs/tutorials/

### 3. gRPC Learning
- **gRPC Official**: https://grpc.io/docs/
- **Python gRPC**: https://grpc.io/docs/languages/python/

## Conclusion

**Recommended Order:**
1. 🥇 **Google Cloud Run** - Simplest, free credits sufficient
2. 🥈 **Oracle Cloud** - Permanent free, sufficient resources
3. 🥉 **AWS ECS** - Powerful, 12-month free

**Start Deployment:**
```bash
# Choose Google Cloud
./student-deploy-gcp.sh

# Or choose Oracle Cloud
# Follow the steps above to create a VM instance
```

---

**🎓 Happy learning! Feel free to ask me any questions!** 