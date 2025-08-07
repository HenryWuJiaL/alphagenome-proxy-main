# 🌤 AlphaGenome 通信代理 - 云部署指南

## 📋 部署概览

本指南将帮助你将 AlphaGenome 通信代理部署到各种云平台：

- **AWS** - 使用 ECS + CloudFormation
- **Google Cloud** - 使用 Cloud Run
- **Azure** - 使用 Container Instances
- **Kubernetes** - 通用 Kubernetes 集群

## 快速部署

### 一键部署脚本

```bash
# 使用自动化部署脚本
./scripts/deploy.sh aws          # AWS 部署
./scripts/deploy.sh gcp          # Google Cloud 部署
./scripts/deploy.sh azure        # Azure 部署
./scripts/deploy.sh kubernetes   # Kubernetes 部署
```

##  AWS 部署

### 前置要求

```bash
# 1. 安装 AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# 2. 配置 AWS 凭证
aws configure
# AWS Access Key ID: your_access_key
# AWS Secret Access Key: your_secret_key
# Default region name: us-east-1
# Default output format: json

# 3. 验证配置
aws sts get-caller-identity
```

### 方法一：使用 CloudFormation（推荐）

```bash
# 1. 设置环境变量
export ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw
export AWS_REGION=us-east-1
export STACK_NAME=alphagenome-proxy

# 2. 创建 CloudFormation 堆栈
aws cloudformation create-stack \
  --stack-name $STACK_NAME \
  --template-body file://deploy/aws/cloudformation.yaml \
  --parameters ParameterKey=ApiKey,ParameterValue=$ALPHAGENOME_API_KEY \
  --capabilities CAPABILITY_IAM \
  --region $AWS_REGION

# 3. 等待部署完成
aws cloudformation wait stack-create-complete \
  --stack-name $STACK_NAME \
  --region $AWS_REGION

# 4. 获取服务 URL
aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs[?OutputKey==`ServiceURL`].OutputValue' \
  --output text
```

### 方法二：使用 ECS CLI

```bash
# 1. 构建并推送镜像到 ECR
aws ecr create-repository --repository-name alphagenome-proxy --region $AWS_REGION
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker build -t alphagenome-proxy .
docker tag alphagenome-proxy:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/alphagenome-proxy:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/alphagenome-proxy:latest

# 2. 创建 ECS 服务
aws ecs create-service \
  --cluster alphagenome-cluster \
  --service-name alphagenome-proxy \
  --task-definition alphagenome-proxy:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-12345,subnet-67890],securityGroups=[sg-12345],assignPublicIp=ENABLED}"
```

### AWS 部署架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │───►│   Application   │───►│   AlphaGenome   │
│   Load Balancer │    │   Load Balancer │    │      API        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│   ECS Service   │    │   ECS Service   │
│   (Task 1)      │    │   (Task 2)      │
└─────────────────┘    └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│   CloudWatch    │    │   CloudWatch    │
│     Logs        │    │     Logs        │
└─────────────────┘    └─────────────────┘
```

##  Google Cloud 部署

### 前置要求

```bash
# 1. 安装 Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# 2. 初始化项目
gcloud init
gcloud auth application-default login

# 3. 设置项目
export PROJECT_ID=your-project-id
gcloud config set project $PROJECT_ID

# 4. 启用必要 API
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### 方法一：使用 Cloud Run（推荐）

```bash
# 1. 构建并推送镜像
docker build -t gcr.io/$PROJECT_ID/alphagenome-proxy .
docker push gcr.io/$PROJECT_ID/alphagenome-proxy

# 2. 创建 Secret
echo -n "AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw" | \
  gcloud secrets create alphagenome-api-key --data-file=-

# 3. 部署到 Cloud Run
gcloud run deploy alphagenome-proxy \
  --image gcr.io/$PROJECT_ID/alphagenome-proxy \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-secrets ALPHAGENOME_API_KEY=alphagenome-api-key:latest \
  --set-env-vars JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com \
  --port 50051 \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 10

# 4. 获取服务 URL
gcloud run services describe alphagenome-proxy \
  --region us-central1 \
  --format 'value(status.url)'
```

### 方法二：使用 GKE

```bash
# 1. 创建 GKE 集群
gcloud container clusters create alphagenome-cluster \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type e2-standard-2

# 2. 获取集群凭证
gcloud container clusters get-credentials alphagenome-cluster \
  --zone us-central1-a

# 3. 应用 Kubernetes 配置
kubectl apply -f deploy/kubernetes/deployment.yaml
kubectl apply -f deploy/kubernetes/service.yaml
kubectl apply -f deploy/kubernetes/ingress.yaml

# 4. 检查部署状态
kubectl get pods
kubectl get services
```

##  Azure 部署

### 前置要求

```bash
# 1. 安装 Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# 2. 登录 Azure
az login

# 3. 设置订阅
az account set --subscription "your-subscription-id"
```

### 使用 Container Instances

```bash
# 1. 创建资源组
az group create --name alphagenome-rg --location eastus

# 2. 创建容器注册表
az acr create --resource-group alphagenome-rg \
  --name alphagenomeregistry --sku Basic

# 3. 构建并推送镜像
az acr build --registry alphagenomeregistry \
  --image alphagenome-proxy:latest .

# 4. 创建容器实例
az container create \
  --resource-group alphagenome-rg \
  --name alphagenome-proxy \
  --image alphagenomeregistry.azurecr.io/alphagenome-proxy:latest \
  --dns-name-label alphagenome-proxy \
  --ports 50051 \
  --environment-variables \
    JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com \
    ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw \
  --cpu 1 \
  --memory 1

# 5. 获取服务 URL
az container show \
  --resource-group alphagenome-rg \
  --name alphagenome-proxy \
  --query "ipAddress.fqdn" \
  --output tsv
```

## ☸ Kubernetes 部署

### 通用 Kubernetes 集群

```bash
# 1. 创建命名空间
kubectl create namespace alphagenome

# 2. 创建 Secret
kubectl create secret generic alphagenome-api-key \
  --from-literal=api-key=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw \
  --namespace alphagenome

# 3. 应用部署配置
kubectl apply -f deploy/kubernetes/deployment.yaml
kubectl apply -f deploy/kubernetes/service.yaml

# 4. 检查部署状态
kubectl get pods -n alphagenome
kubectl get services -n alphagenome
```

### Kubernetes 配置文件

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
        image: alphagenome-proxy:latest
        ports:
        - containerPort: 50051
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
            port: 50051
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 50051
          initialDelaySeconds: 5
          periodSeconds: 5
```

## 配置管理

### 环境变量配置

```bash
# 生产环境配置
export ENVIRONMENT=production
export ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw
export JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com
export API_KEY_HEADER=Authorization
export API_KEY_PREFIX=Bearer
export LOG_LEVEL=INFO
export MAX_WORKERS=10
export REQUEST_TIMEOUT=30
```

### 配置文件

```yaml
# config/production.yaml
api:
  host: 0.0.0.0
  port: 50051
  max_workers: 10
  request_timeout: 30

alphagenome:
  api_key: ${ALPHAGENOME_API_KEY}
  base_url: ${JSON_SERVICE_BASE_URL}
  headers:
    authorization: Bearer ${ALPHAGENOME_API_KEY}

logging:
  level: INFO
  format: json
  output: stdout

monitoring:
  enabled: true
  metrics_port: 9090
  health_check_path: /health
```

## 监控和日志

### CloudWatch 监控（AWS）

```bash
# 创建 CloudWatch 仪表板
aws cloudwatch put-dashboard \
  --dashboard-name alphagenome-proxy \
  --dashboard-body file://monitoring/cloudwatch-dashboard.json

# 设置告警
aws cloudwatch put-metric-alarm \
  --alarm-name alphagenome-proxy-high-cpu \
  --alarm-description "High CPU usage" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold
```

### Stackdriver 监控（GCP）

```bash
# 启用 Stackdriver 监控
gcloud services enable monitoring.googleapis.com

# 创建监控策略
gcloud alpha monitoring policies create \
  --policy-from-file=monitoring/stackdriver-policy.yaml
```

### 日志聚合

```bash
# 使用 Fluentd 收集日志
kubectl apply -f monitoring/fluentd-configmap.yaml
kubectl apply -f monitoring/fluentd-daemonset.yaml

# 或使用 ELK Stack
docker-compose -f monitoring/elk-stack.yml up -d
```

## 安全配置

### 网络安全

```bash
# AWS Security Groups
aws ec2 create-security-group \
  --group-name alphagenome-proxy-sg \
  --description "Security group for AlphaGenome proxy" \
  --vpc-id vpc-12345

aws ec2 authorize-security-group-ingress \
  --group-id sg-12345 \
  --protocol tcp \
  --port 50051 \
  --cidr 0.0.0.0/0
```

### 密钥管理

```bash
# AWS Secrets Manager
aws secretsmanager create-secret \
  --name alphagenome-api-key \
  --description "AlphaGenome API Key" \
  --secret-string "AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw"

# Google Secret Manager
echo -n "AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw" | \
  gcloud secrets create alphagenome-api-key --data-file=-

# Azure Key Vault
az keyvault secret set \
  --vault-name alphagenome-vault \
  --name alphagenome-api-key \
  --value "AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw"
```

## 自动化部署

### CI/CD 流水线

```yaml
# .github/workflows/deploy.yml
name: Deploy to Cloud

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Build Docker image
      run: docker build -t alphagenome-proxy .
    
    - name: Deploy to AWS
      if: github.ref == 'refs/heads/main'
      run: |
        aws ecr get-login-password | docker login --username AWS --password-stdin ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com
        docker tag alphagenome-proxy:latest ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/alphagenome-proxy:latest
        docker push ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/alphagenome-proxy:latest
        aws ecs update-service --cluster alphagenome-cluster --service alphagenome-proxy --force-new-deployment
```

### Terraform 配置

```hcl
# terraform/main.tf
provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "alphagenome" {
  name = "alphagenome-cluster"
}

resource "aws_ecs_task_definition" "alphagenome_proxy" {
  family                   = "alphagenome-proxy"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name  = "alphagenome-proxy"
      image = "alphagenome-proxy:latest"
      portMappings = [
        {
          containerPort = 50051
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "ALPHAGENOME_API_KEY"
          value = var.api_key
        }
      ]
    }
  ])
}
```

## 📈 性能优化

### 自动扩缩容

```bash
# AWS ECS 自动扩缩容
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/alphagenome-cluster/alphagenome-proxy \
  --min-capacity 1 \
  --max-capacity 10

aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/alphagenome-cluster/alphagenome-proxy \
  --policy-name cpu-scaling-policy \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration file://scaling/cpu-policy.json
```

### 负载均衡

```bash
# 创建 Application Load Balancer
aws elbv2 create-load-balancer \
  --name alphagenome-alb \
  --subnets subnet-12345 subnet-67890 \
  --security-groups sg-12345

# 创建目标组
aws elbv2 create-target-group \
  --name alphagenome-tg \
  --protocol HTTP \
  --port 50051 \
  --vpc-id vpc-12345 \
  --target-type ip
```

##  故障排除

### 常见问题

#### 1. 服务无法启动

```bash
# 检查容器日志
docker logs alphagenome-proxy
kubectl logs -f deployment/alphagenome-proxy

# 检查健康状态
curl -X GET http://localhost:50051/health
```

#### 2. API Key 错误

```bash
# 验证环境变量
docker exec alphagenome-proxy env | grep ALPHAGENOME_API_KEY
kubectl exec deployment/alphagenome-proxy -- env | grep ALPHAGENOME_API_KEY

# 重新设置 Secret
kubectl delete secret alphagenome-api-key
kubectl create secret generic alphagenome-api-key \
  --from-literal=api-key=your_new_api_key
```

#### 3. 网络连接问题

```bash
# 测试网络连接
curl -X GET https://api.alphagenome.google.com/health

# 检查防火墙规则
aws ec2 describe-security-groups --group-ids sg-12345
```

### 调试工具

```bash
# 端口转发（Kubernetes）
kubectl port-forward deployment/alphagenome-proxy 50051:50051

# 进入容器调试
docker exec -it alphagenome-proxy /bin/bash
kubectl exec -it deployment/alphagenome-proxy -- /bin/bash

# 查看资源使用
docker stats alphagenome-proxy
kubectl top pods
```

## 📞 支持

- [用户指南](USER_GUIDE.md)
- 🐛 [问题报告](https://github.com/your-repo/alphagenome-proxy/issues)
- 💬 [讨论](https://github.com/your-repo/alphagenome-proxy/discussions)

---

** 恭喜！你的 AlphaGenome 通信代理已成功部署到云端！** 