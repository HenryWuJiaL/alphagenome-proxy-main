# 🚀 AlphaGenome 代理服务部署包

## 📦 部署包内容

这个包包含了在 Google Cloud 上部署 AlphaGenome 代理服务所需的所有文件。

### 📁 文件结构

```
deployment-package/
├── README.md                    # 本文件
├── deploy.sh                    # 一键部署脚本
├── Dockerfile                   # 容器镜像定义
├── requirements.txt             # Python 依赖
├── src/                         # 源代码
│   └── alphagenome/
│       ├── __init__.py
│       ├── main.py              # 主服务文件
│       ├── protos/              # protobuf 定义
│       └── models/              # 模型文件
├── config/                      # 配置文件
│   ├── service.yaml            # Cloud Run 服务配置
│   └── .env.example            # 环境变量示例
└── scripts/                     # 辅助脚本
    ├── setup-gcp.sh            # GCP 环境设置
    └── test-service.sh         # 服务测试脚本
```

## 🎯 部署前准备

### 1. **Google Cloud 项目设置**

```bash
# 1. 创建新项目（如果还没有）
gcloud projects create YOUR_PROJECT_ID --name="AlphaGenome Proxy"

# 2. 设置项目
gcloud config set project YOUR_PROJECT_ID

# 3. 启用必要的 API
gcloud services enable \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  storage.googleapis.com \
  containerregistry.googleapis.com
```

### 2. **服务账号设置**

```bash
# 1. 创建服务账号
gcloud iam service-accounts create alphagenome-proxy \
  --display-name="AlphaGenome Proxy Service Account"

# 2. 分配权限
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:alphagenome-proxy@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:alphagenome-proxy@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:alphagenome-proxy@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# 3. 创建密钥文件（可选，用于本地测试）
gcloud iam service-accounts keys create key.json \
  --iam-account=alphagenome-proxy@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

### 3. **环境变量配置**

复制 `.env.example` 到 `.env` 并填写：

```bash
# AlphaGenome API 配置
ALPHAGENOME_API_KEY=your_alphagenome_api_key_here

# Google Cloud 配置
PROJECT_ID=your_project_id_here
REGION=us-central1
SERVICE_NAME=alphagenome-proxy

# 服务配置
PORT=8080
MEMORY=512Mi
CPU=1
MAX_INSTANCES=10
```

## 🚀 快速部署

### 方法 1: 一键部署脚本

```bash
# 1. 设置环境变量
export PROJECT_ID=your_project_id_here
export ALPHAGENOME_API_KEY=your_api_key_here

# 2. 运行部署脚本
chmod +x deploy.sh
./deploy.sh
```

### 方法 2: 手动部署

```bash
# 1. 构建镜像
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME

# 2. 部署到 Cloud Run
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --memory $MEMORY \
  --cpu $CPU \
  --max-instances $MAX_INSTANCES \
  --set-env-vars ALPHAGENOME_API_KEY=$ALPHAGENOME_API_KEY
```

## 🧪 测试部署

```bash
# 运行测试脚本
chmod +x scripts/test-service.sh
./scripts/test-service.sh
```

## 📊 监控和日志

```bash
# 查看服务日志
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME" --limit=50

# 查看服务状态
gcloud run services describe $SERVICE_NAME --region=$REGION

# 查看服务 URL
gcloud run services list --filter="metadata.name=$SERVICE_NAME"
```

## 🔧 自定义配置

### 修改服务配置

编辑 `config/service.yaml` 来调整服务参数：

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: alphagenome-proxy
spec:
  template:
    spec:
      containers:
      - image: gcr.io/YOUR_PROJECT_ID/alphagenome-proxy
        ports:
        - containerPort: 8080
        resources:
          limits:
            memory: "512Mi"
            cpu: "1"
        env:
        - name: ALPHAGENOME_API_KEY
          value: "your_api_key_here"
```

### 修改 Dockerfile

编辑 `Dockerfile` 来调整容器配置：

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY src/ ./src/

EXPOSE 8080

CMD ["python", "-m", "alphagenome.main"]
```

## 💰 成本估算

### 免费额度（每月）
- **Cloud Run**: 200万请求
- **Cloud Build**: 120分钟构建时间
- **Container Registry**: 0.5GB 存储
- **网络**: 15GB 出站流量

### 超出免费额度的成本
- **Cloud Run**: $0.00002400/100ms
- **Cloud Build**: $0.003/分钟
- **网络**: $0.12/GB

**典型使用场景（每月 10万请求）**: 几乎免费

## 🔒 安全考虑

### 1. **API 密钥安全**
- 使用环境变量存储 API 密钥
- 不要将密钥提交到代码仓库
- 定期轮换 API 密钥

### 2. **网络安全**
- 使用 HTTPS 加密传输
- 配置适当的 CORS 策略
- 考虑使用 VPC 网络隔离

### 3. **访问控制**
- 使用 IAM 角色控制访问
- 定期审查权限
- 启用审计日志

## 🆘 故障排除

### 常见问题

1. **构建失败**
   ```bash
   # 检查构建日志
   gcloud builds log BUILD_ID
   ```

2. **服务启动失败**
   ```bash
   # 检查服务日志
   gcloud logging read "resource.type=cloud_run_revision"
   ```

3. **API 调用失败**
   ```bash
   # 验证 API 密钥
   curl -H "Authorization: Bearer $ALPHAGENOME_API_KEY" \
     https://api.alphagenome.com/v1/health
   ```

### 获取帮助

- 📧 **邮箱**: your-email@example.com
- 📖 **文档**: [项目文档链接]
- 🐛 **Issues**: [GitHub Issues 链接]

## 📝 许可证

本项目基于 MIT 许可证开源。

---

**部署完成后，你的服务将在以下地址可用：**
`https://alphagenome-proxy-xxxxx-uc.a.run.app` 