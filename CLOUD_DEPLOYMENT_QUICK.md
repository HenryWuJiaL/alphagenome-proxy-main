# 云部署快速指南

## 📋 部署选项

| 平台 | 推荐方案 | 部署时间 | 成本 |
|------|----------|----------|------|
| **AWS** | ECS + CloudFormation | 10分钟 | $10-50/月 |
| **Google Cloud** | Cloud Run | 5分钟 | $5-30/月 |
| **Azure** | Container Instances | 8分钟 | $8-40/月 |
| **Kubernetes** | 通用集群 | 15分钟 | 取决于集群 |

## ⚡ 一键部署

### 1. 准备环境

```bash
# 设置 API Key
export ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw

# 运行部署脚本
./scripts/deploy.sh aws          # AWS 部署
./scripts/deploy.sh gcp          # Google Cloud 部署
./scripts/deploy.sh azure        # Azure 部署
./scripts/deploy.sh kubernetes   # Kubernetes 部署
```

##  AWS 部署（推荐）

### 步骤 1：安装 AWS CLI

```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# 配置
aws configure
```

### 步骤 2：一键部署

```bash
# 设置变量
export ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw
export AWS_REGION=us-east-1

# 部署
aws cloudformation create-stack \
  --stack-name alphagenome-proxy \
  --template-body file://deploy/aws/cloudformation.yaml \
  --parameters ParameterKey=ApiKey,ParameterValue=$ALPHAGENOME_API_KEY \
  --capabilities CAPABILITY_IAM

# 等待完成
aws cloudformation wait stack-create-complete --stack-name alphagenome-proxy

# 获取服务地址
aws cloudformation describe-stacks \
  --stack-name alphagenome-proxy \
  --query 'Stacks[0].Outputs[?OutputKey==`ServiceURL`].OutputValue' \
  --output text
```

##  Google Cloud 部署

### 步骤 1：安装 Google Cloud SDK

```bash
# macOS
brew install google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# 初始化
gcloud init
```

### 步骤 2：一键部署

```bash
# 设置项目
export PROJECT_ID=your-project-id
gcloud config set project $PROJECT_ID

# 构建并部署
docker build -t gcr.io/$PROJECT_ID/alphagenome-proxy .
docker push gcr.io/$PROJECT_ID/alphagenome-proxy

# 创建 Secret
echo -n "AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw" | \
  gcloud secrets create alphagenome-api-key --data-file=-

# 部署到 Cloud Run
gcloud run deploy alphagenome-proxy \
  --image gcr.io/$PROJECT_ID/alphagenome-proxy \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-secrets ALPHAGENOME_API_KEY=alphagenome-api-key:latest \
  --port 50051
```

## ☸ Kubernetes 部署

### 步骤 1：准备集群

```bash
# 创建命名空间
kubectl create namespace alphagenome

# 创建 Secret
kubectl create secret generic alphagenome-api-key \
  --from-literal=api-key=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw \
  --namespace alphagenome
```

### 步骤 2：部署服务

```bash
# 应用配置
kubectl apply -f deploy/kubernetes/deployment.yaml
kubectl apply -f deploy/kubernetes/service.yaml

# 检查状态
kubectl get pods -n alphagenome
kubectl get services -n alphagenome
```

## 配置管理

### 环境变量

```bash
# 必需配置
ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw
JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com

# 可选配置
API_KEY_HEADER=Authorization
API_KEY_PREFIX=Bearer
LOG_LEVEL=INFO
```

### 端口配置

- **gRPC 服务**: 50051
- **健康检查**: /health
- **就绪检查**: /ready

## 监控和验证

### 健康检查

```bash
# 检查服务状态
curl -X GET http://your-service-url/health

# 测试 gRPC 连接
python -c "
import grpc
from alphagenome.protos import dna_model_service_pb2_grpc
channel = grpc.insecure_channel('your-service-url:50051')
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)
print(' 连接成功')
"
```

### 性能监控

```bash
# AWS CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=alphagenome-proxy \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 300 \
  --statistics Average

# Google Cloud Monitoring
gcloud monitoring metrics list --filter="metric.type:run.googleapis.com"
```

##  故障排除

### 常见问题

**Q: 服务无法启动**
```bash
# 检查日志
docker logs alphagenome-proxy
kubectl logs -f deployment/alphagenome-proxy

# 检查配置
docker exec alphagenome-proxy env | grep ALPHAGENOME
```

**Q: API Key 错误**
```bash
# 重新设置 Secret
kubectl delete secret alphagenome-api-key
kubectl create secret generic alphagenome-api-key \
  --from-literal=api-key=your_new_api_key

# 重启服务
kubectl rollout restart deployment/alphagenome-proxy
```

**Q: 网络连接问题**
```bash
# 测试连接
curl -X GET https://api.alphagenome.google.com/health

# 检查防火墙
aws ec2 describe-security-groups --group-ids sg-12345
```

### 调试命令

```bash
# 端口转发
kubectl port-forward deployment/alphagenome-proxy 50051:50051

# 进入容器
docker exec -it alphagenome-proxy /bin/bash
kubectl exec -it deployment/alphagenome-proxy -- /bin/bash

# 查看资源
docker stats alphagenome-proxy
kubectl top pods -n alphagenome
```

## 成本估算

### AWS ECS
- **计算**: $10-30/月 (Fargate)
- **网络**: $5-15/月 (ALB + 数据传输)
- **存储**: $1-5/月 (CloudWatch 日志)
- **总计**: $16-50/月

### Google Cloud Run
- **计算**: $5-20/月 (按请求计费)
- **网络**: $2-10/月 (出站流量)
- **存储**: $1-3/月 (日志)
- **总计**: $8-33/月

### Azure Container Instances
- **计算**: $8-25/月 (按使用时间)
- **网络**: $5-12/月 (出站流量)
- **存储**: $1-4/月 (日志)
- **总计**: $14-41/月

## 扩展配置

### 自动扩缩容

```bash
# AWS ECS 自动扩缩容
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/alphagenome-cluster/alphagenome-proxy \
  --min-capacity 1 \
  --max-capacity 10

# Google Cloud Run 自动扩缩容
gcloud run services update alphagenome-proxy \
  --min-instances 1 \
  --max-instances 10 \
  --region us-central1
```

### 负载均衡

```bash
# 创建多个实例
kubectl scale deployment alphagenome-proxy --replicas=3

# 配置负载均衡器
kubectl apply -f deploy/kubernetes/ingress.yaml
```

## 📞 支持

- [完整部署指南](CLOUD_DEPLOYMENT_GUIDE.md)
- 🐛 [问题报告](https://github.com/your-repo/alphagenome-proxy/issues)
- 💬 [讨论](https://github.com/your-repo/alphagenome-proxy/discussions)

---

** 你的 AlphaGenome 通信代理已成功部署到云端！** 