# 🎓 学生免费云部署指南

## 🆓 免费云平台对比

| 平台 | 免费额度 | 申请难度 | 推荐指数 |
|------|----------|----------|----------|
| **Google Cloud** | $300 + Always Free | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **AWS** | 12个月免费套餐 | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Azure** | $100 学生额度 | ⭐⭐ | ⭐⭐⭐⭐ |
| **Oracle Cloud** | 永久免费 | ⭐⭐⭐ | ⭐⭐⭐ |

## 🚀 Google Cloud 部署（推荐）

### 步骤 1：注册学生账户

1. **访问 Google Cloud 学生页面**
   ```
   https://cloud.google.com/edu
   ```

2. **使用教育邮箱注册**
   - 使用你的学校邮箱（如：student@university.edu）
   - 验证学生身份

3. **获得免费额度**
   - $300 免费额度（90天）
   - Always Free 套餐（永久）

### 步骤 2：创建项目

```bash
# 安装 Google Cloud SDK
# macOS
brew install google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# 初始化项目
gcloud init

# 创建新项目
gcloud projects create alphagenome-student-project

# 设置项目
gcloud config set project alphagenome-student-project

# 启用必要服务
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### 步骤 3：部署应用

```bash
# 设置环境变量
export PROJECT_ID=alphagenome-student-project
export ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw

# 构建 Docker 镜像
docker build -t gcr.io/$PROJECT_ID/alphagenome-proxy .

# 推送镜像到 Google Container Registry
docker push gcr.io/$PROJECT_ID/alphagenome-proxy

# 部署到 Cloud Run
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

# 获取服务 URL
gcloud run services describe alphagenome-proxy \
  --region us-central1 \
  --format 'value(status.url)'
```

### 步骤 4：测试服务

```bash
# 测试健康检查
curl -X GET https://your-service-url/health

# 测试 gRPC 连接
python -c "
import grpc
from alphagenome.protos import dna_model_service_pb2_grpc
channel = grpc.insecure_channel('your-service-url:50051')
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)
print('✅ 连接成功')
"
```

## 🆓 AWS 免费部署

### 步骤 1：注册 AWS 免费账户

1. **访问 AWS Free Tier**
   ```
   https://aws.amazon.com/free/
   ```

2. **注册账户**
   - 需要信用卡验证（不会收费）
   - 获得 12个月免费套餐

### 步骤 2：部署到 ECS

```bash
# 安装 AWS CLI
# macOS
brew install awscli

# 配置 AWS
aws configure

# 创建 ECR 仓库
aws ecr create-repository --repository-name alphagenome-proxy

# 登录 ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# 构建并推送镜像
docker build -t alphagenome-proxy .
docker tag alphagenome-proxy:latest $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/alphagenome-proxy:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/alphagenome-proxy:latest

# 使用 CloudFormation 部署
aws cloudformation create-stack \
  --stack-name alphagenome-student \
  --template-body file://deploy/aws/cloudformation.yaml \
  --parameters ParameterKey=ApiKey,ParameterValue=$ALPHAGENOME_API_KEY \
  --capabilities CAPABILITY_IAM
```

## 🆓 Oracle Cloud 永久免费

### 步骤 1：注册 Oracle Cloud

1. **访问 Oracle Cloud Free Tier**
   ```
   https://www.oracle.com/cloud/free/
   ```

2. **注册账户**
   - 需要信用卡验证
   - 获得永久免费套餐

### 步骤 2：创建 VM 实例

```bash
# 创建 VM 实例
# 选择 Oracle Linux
# 配置：1 OCPU, 6GB RAM

# 连接到实例
ssh opc@your-instance-ip

# 安装 Docker
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker opc

# 重新登录
exit
ssh opc@your-instance-ip

# 部署应用
docker run -d \
  --name alphagenome-proxy \
  -p 50051:50051 \
  -e ALPHAGENOME_API_KEY=$ALPHAGENOME_API_KEY \
  -e JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com \
  alphagenome-proxy:latest
```

## 💰 成本对比

### Google Cloud Run
- **免费额度**: 每月 200万请求
- **超出费用**: $0.0000024/请求
- **学生优惠**: $300 免费额度
- **总成本**: 几乎免费

### AWS ECS
- **免费额度**: 每月 40万秒 Fargate
- **超出费用**: $0.04048/vCPU-小时
- **学生优惠**: 12个月免费
- **总成本**: 免费（12个月内）

### Oracle Cloud
- **免费额度**: 永久免费
- **资源**: 2个 VM 实例
- **学生优惠**: 无额外优惠
- **总成本**: 永久免费

## 🎯 学生专属优惠

### 1. GitHub Student Developer Pack
```
https://education.github.com/pack
```
- 多个云平台免费额度
- 开发工具免费使用
- 学习资源

### 2. Microsoft Azure for Students
```
https://azure.microsoft.com/zh-cn/free/students/
```
- $100 免费额度
- 无时间限制
- 40+ 服务免费

### 3. Google Cloud for Students
```
https://cloud.google.com/edu
```
- 额外学习资源
- 认证考试优惠
- 社区支持

## 🛠️ 一键部署脚本

### Google Cloud 一键部署

```bash
#!/bin/bash
# student-deploy-gcp.sh

set -e

echo "🎓 学生 Google Cloud 部署脚本"

# 检查依赖
if ! command -v gcloud &> /dev/null; then
    echo "❌ 请先安装 Google Cloud SDK"
    exit 1
fi

# 设置变量
export PROJECT_ID=alphagenome-student-$(date +%s)
export ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw

echo "📦 创建项目: $PROJECT_ID"
gcloud projects create $PROJECT_ID
gcloud config set project $PROJECT_ID

echo "🔧 启用服务"
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

echo "🐳 构建镜像"
docker build -t gcr.io/$PROJECT_ID/alphagenome-proxy .
docker push gcr.io/$PROJECT_ID/alphagenome-proxy

echo "🚀 部署到 Cloud Run"
gcloud run deploy alphagenome-proxy \
  --image gcr.io/$PROJECT_ID/alphagenome-proxy \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars ALPHAGENOME_API_KEY=$ALPHAGENOME_API_KEY \
  --port 50051

echo "✅ 部署完成！"
echo "🌐 服务地址:"
gcloud run services describe alphagenome-proxy \
  --region us-central1 \
  --format 'value(status.url)'
```

### 使用方法

```bash
# 给脚本执行权限
chmod +x student-deploy-gcp.sh

# 运行部署
./student-deploy-gcp.sh
```

## 📚 学习资源

### 1. 云平台学习
- **Google Cloud**: https://cloud.google.com/learn
- **AWS**: https://aws.amazon.com/training/
- **Azure**: https://docs.microsoft.com/learn/

### 2. 容器化学习
- **Docker**: https://docs.docker.com/get-started/
- **Kubernetes**: https://kubernetes.io/docs/tutorials/

### 3. gRPC 学习
- **gRPC 官方**: https://grpc.io/docs/
- **Python gRPC**: https://grpc.io/docs/languages/python/

## 🎉 总结

**推荐顺序：**
1. 🥇 **Google Cloud Run** - 最简单，免费额度充足
2. 🥈 **Oracle Cloud** - 永久免费，资源充足
3. 🥉 **AWS ECS** - 功能强大，12个月免费

**开始部署：**
```bash
# 选择 Google Cloud
./student-deploy-gcp.sh

# 或选择 Oracle Cloud
# 按照上面的步骤创建 VM 实例
```

---

**🎓 祝你学习愉快！有任何问题都可以问我！** 