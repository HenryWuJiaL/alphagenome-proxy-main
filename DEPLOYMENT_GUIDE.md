# AlphaGenome Communication Proxy 部署指南

本文档提供在不同环境中部署 AlphaGenome Communication Proxy 的完整指南。

## 目录

1. [快速开始](#快速开始)
2. [环境要求](#环境要求)
3. [本地开发环境](#本地开发环境)
4. [Docker 部署](#docker-部署)
5. [AWS 部署](#aws-部署)
6. [Google Cloud 部署](#google-cloud-部署)
7. [Kubernetes 部署](#kubernetes-部署)
8. [Windows 部署](#windows-部署)
9. [监控和维护](#监控和维护)
10. [故障排除](#故障排除)

## 快速开始

### 1. 自动安装依赖

```bash
# 克隆项目
git clone <repository-url>
cd alphagenome-main

# 自动安装所有依赖
./scripts/install-dependencies.sh

# 设置 API Key
export ALPHAGENOME_API_KEY=your_api_key_here

# 运行测试
python -m pytest src/alphagenome/communication_proxy_test.py -v

# 本地 Docker 部署
./scripts/deploy.sh local-docker
```

### 2. 手动安装

```bash
# 安装 Python 3.11
# Ubuntu/Debian
sudo apt-get install python3.11 python3.11-pip python3.11-venv

# macOS
brew install python@3.11

# 创建虚拟环境
python3.11 -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt
```

## 环境要求

### 最低要求
- **CPU**: 1 核心
- **内存**: 512MB RAM
- **存储**: 1GB 可用空间
- **网络**: 互联网连接

### 推荐配置
- **CPU**: 2+ 核心
- **内存**: 2GB+ RAM
- **存储**: 5GB+ 可用空间
- **网络**: 稳定的互联网连接

### 支持的操作系统
- **Linux**: Ubuntu 18.04+, CentOS 7+, RHEL 7+
- **macOS**: 10.14+ (Mojave+)
- **Windows**: Windows 10+ (WSL2 推荐)

## 本地开发环境

### 1. 环境设置

```bash
# 激活虚拟环境
source venv/bin/activate

# 设置环境变量
export ALPHAGENOME_API_KEY=your_api_key_here
export JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com

# 运行测试
python -m pytest src/alphagenome/communication_proxy_test.py -v
```

### 2. 启动服务

```bash
# 直接启动
python -c "from alphagenome import communication_proxy; communication_proxy.serve()"

# 或使用 Docker Compose
docker-compose up -d
```

### 3. 测试连接

```bash
# 使用测试脚本
python test_communication_proxy_manual.py

# 使用 grpcurl (可选)
grpcurl -plaintext localhost:50051 list
```

## Docker 部署

### 1. 构建镜像

```bash
# 构建镜像
docker build -t alphagenome-proxy:latest .

# 或使用脚本
./scripts/deploy.sh --build
```

### 2. 运行容器

```bash
# 基本运行
docker run -d \
  --name alphagenome-proxy \
  -p 50051:50051 \
  -e ALPHAGENOME_API_KEY=your_api_key_here \
  alphagenome-proxy:latest

# 使用 Docker Compose
docker-compose up -d
```

### 3. 生产环境配置

```bash
# 创建生产环境配置
cp config_example.env .env
# 编辑 .env 文件

# 使用生产配置启动
docker-compose -f docker-compose.prod.yml up -d
```

## AWS 部署

### 1. 准备工作

```bash
# 安装 AWS CLI
./scripts/install-dependencies.sh --aws-only

# 配置 AWS 凭证
aws configure

# 设置 API Key
export ALPHAGENOME_API_KEY=your_api_key_here
```

### 2. 自动部署

```bash
# 部署到生产环境
./scripts/deploy.sh aws production us-east-1

# 部署到开发环境
./scripts/deploy.sh aws development us-west-2
```

### 3. 手动部署

```bash
# 构建并推送镜像到 ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

docker build -t alphagenome-proxy .
docker tag alphagenome-proxy:latest $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/alphagenome-proxy:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/alphagenome-proxy:latest

# 部署 CloudFormation 栈
aws cloudformation deploy \
  --template-file deploy/aws/cloudformation.yaml \
  --stack-name alphagenome-proxy-production \
  --parameter-overrides ApiKey=$ALPHAGENOME_API_KEY Environment=production \
  --capabilities CAPABILITY_IAM
```

### 4. 监控和日志

```bash
# 查看 CloudWatch 日志
aws logs describe-log-groups --log-group-name-prefix "/ecs/alphagenome-proxy"

# 查看 ECS 服务状态
aws ecs describe-services \
  --cluster alphagenome-proxy-production \
  --services alphagenome-proxy-production
```

## Google Cloud 部署

### 1. 准备工作

```bash
# 安装 Google Cloud SDK
./scripts/install-dependencies.sh --gcp-only

# 初始化项目
gcloud init

# 启用必要服务
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### 2. 自动部署

```bash
# 部署到 Cloud Run
./scripts/deploy.sh gcp your-project-id us-central1
```

### 3. 手动部署

```bash
# 构建并推送镜像
docker build -t gcr.io/YOUR_PROJECT_ID/alphagenome-proxy .
docker push gcr.io/YOUR_PROJECT_ID/alphagenome-proxy

# 创建 Secret
echo -n "your_api_key_here" | \
  gcloud secrets create alphagenome-api-key --data-file=-

# 部署到 Cloud Run
gcloud run deploy alphagenome-proxy \
  --image gcr.io/YOUR_PROJECT_ID/alphagenome-proxy \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-secrets ALPHAGENOME_API_KEY=alphagenome-api-key:latest
```

## Kubernetes 部署

### 1. 准备工作

```bash
# 安装 kubectl
./scripts/install-dependencies.sh --k8s-only

# 配置集群访问
kubectl config use-context your-cluster-context
```

### 2. 部署应用

```bash
# 创建命名空间
kubectl create namespace alphagenome

# 创建 Secret
kubectl create secret generic alphagenome-api-key \
  --from-literal=api-key=your_api_key_here \
  --namespace alphagenome

# 部署应用
kubectl apply -f deploy/kubernetes/deployment.yaml -n alphagenome
```

### 3. 验证部署

```bash
# 查看 Pod 状态
kubectl get pods -n alphagenome

# 查看服务
kubectl get svc -n alphagenome

# 查看日志
kubectl logs -f deployment/alphagenome-proxy -n alphagenome
```

## Windows 部署

### 1. WSL2 环境 (推荐)

```bash
# 在 WSL2 中运行 Linux 版本的脚本
wsl
./scripts/install-dependencies.sh
./scripts/deploy.sh local-docker
```

### 2. 原生 Windows

```bash
# 安装 Python
# 下载并安装 Python 3.11: https://www.python.org/downloads/

# 安装 Docker Desktop
# 下载并安装: https://www.docker.com/products/docker-desktop

# 创建虚拟环境
python -m venv venv
venv\Scripts\activate

# 安装依赖
pip install -r requirements.txt

# 设置环境变量
set ALPHAGENOME_API_KEY=your_api_key_here

# 运行服务
python -c "from alphagenome import communication_proxy; communication_proxy.serve()"
```

### 3. PowerShell 脚本

```powershell
# 创建 PowerShell 部署脚本
# 参考 scripts/deploy.ps1 (需要创建)
```

## 监控和维护

### 1. 健康检查

```bash
# 检查服务状态
curl http://localhost:50051/health

# Docker 健康检查
docker ps --filter "name=alphagenome-proxy"

# Kubernetes 健康检查
kubectl get pods -n alphagenome -o wide
```

### 2. 日志监控

```bash
# 查看实时日志
docker logs -f alphagenome-proxy

# 查看特定时间段的日志
docker logs --since "2024-01-01T00:00:00" alphagenome-proxy

# Kubernetes 日志
kubectl logs -f deployment/alphagenome-proxy -n alphagenome
```

### 3. 性能监控

```bash
# 查看资源使用情况
docker stats alphagenome-proxy

# Kubernetes 资源监控
kubectl top pods -n alphagenome
```

### 4. 备份和恢复

```bash
# 备份配置
cp config_example.env config_backup.env

# 备份 Docker 镜像
docker save alphagenome-proxy:latest > alphagenome-proxy-backup.tar

# 恢复镜像
docker load < alphagenome-proxy-backup.tar
```

## 故障排除

### 常见问题

#### 1. API Key 错误
```bash
# 检查环境变量
echo $ALPHAGENOME_API_KEY

# 重新设置
export ALPHAGENOME_API_KEY=your_api_key_here
```

#### 2. 端口冲突
```bash
# 检查端口占用
lsof -i :50051

# 修改端口
export GRPC_PORT=50052
```

#### 3. 网络连接问题
```bash
# 测试网络连接
curl -I https://api.alphagenome.google.com

# 检查防火墙设置
sudo ufw status
```

#### 4. 内存不足
```bash
# 增加 Docker 内存限制
docker run -m 1g alphagenome-proxy:latest

# Kubernetes 资源限制
kubectl patch deployment alphagenome-proxy \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"alphagenome-proxy","resources":{"limits":{"memory":"1Gi"}}}]}}}}'
```

### 调试模式

```bash
# 启用调试日志
export LOG_LEVEL=DEBUG

# 启动调试模式
python -c "
import logging
logging.basicConfig(level=logging.DEBUG)
from alphagenome import communication_proxy
communication_proxy.serve()
"
```

### 获取帮助

```bash
# 查看脚本帮助
./scripts/deploy.sh --help
./scripts/install-dependencies.sh --help

# 查看文档
cat README.md
cat TESTING_GUIDE.md
```

## 安全最佳实践

### 1. API Key 管理
- 使用环境变量或密钥管理服务
- 定期轮换 API Key
- 限制 API Key 权限

### 2. 网络安全
- 使用 HTTPS/TLS
- 配置防火墙规则
- 启用网络策略

### 3. 容器安全
- 使用非 root 用户运行容器
- 定期更新基础镜像
- 扫描镜像漏洞

### 4. 监控和告警
- 设置资源使用告警
- 监控错误率
- 配置日志聚合

---

## 总结

本部署指南涵盖了从本地开发到生产环境的完整部署流程。根据你的具体需求选择合适的部署方式：

- **开发测试**: 使用本地 Docker 部署
- **小规模生产**: 使用 Docker Compose
- **大规模生产**: 使用 AWS ECS 或 GKE
- **混合云**: 使用 Kubernetes

如有问题，请参考故障排除部分或查看项目文档。 