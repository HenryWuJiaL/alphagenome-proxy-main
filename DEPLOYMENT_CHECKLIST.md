# 📋 部署到别人 Google Cloud 的信息清单

## 🎯 **你需要提供的信息**

### 1. **Google Cloud 项目信息** ⭐⭐⭐⭐⭐

```bash
# 必需信息
PROJECT_ID=your-project-id-here
PROJECT_NAME=your-project-name-here

# 示例
PROJECT_ID=my-alphagenome-project
PROJECT_NAME=AlphaGenome Proxy Project
```

**如何获取：**
- 登录 [Google Cloud Console](https://console.cloud.google.com/)
- 在顶部导航栏查看项目 ID
- 或在终端运行：`gcloud projects list`

### 2. **AlphaGenome API 密钥** ⭐⭐⭐⭐⭐

```bash
# 必需信息
ALPHAGENOME_API_KEY=your-api-key-here

# 示例
ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw
```

**如何获取：**
- 访问 [AlphaGenome Console](https://console.cloud.google.com/apis/credentials)
- 创建新的 API 密钥
- 或使用现有的密钥

### 3. **服务账号信息** ⭐⭐⭐⭐

```bash
# 服务账号邮箱（自动生成）
SERVICE_ACCOUNT_EMAIL=alphagenome-proxy@your-project-id.iam.gserviceaccount.com

# 需要的权限
REQUIRED_ROLES=(
  "roles/run.admin"           # Cloud Run 管理
  "roles/storage.admin"       # Cloud Storage 管理
  "roles/iam.serviceAccountUser"  # 服务账号使用
  "roles/cloudbuild.builds.builder"  # Cloud Build 构建
)
```

**注意：** 部署脚本会自动创建服务账号和分配权限

### 4. **部署配置** ⭐⭐⭐

```bash
# 服务配置
SERVICE_NAME=alphagenome-proxy
REGION=us-central1
PORT=8080

# 资源限制
MEMORY=512Mi
CPU=1
MAX_INSTANCES=10

# 网络配置
ALLOW_UNAUTHENTICATED=true
```

### 5. **网络和域名** ⭐⭐

```bash
# 服务 URL（自动生成）
SERVICE_URL=https://alphagenome-proxy-xxxxx-uc.a.run.app

# gRPC 端点
GRPC_ENDPOINT=alphagenome-proxy-xxxxx-uc.a.run.app:443

# 自定义域名（可选）
CUSTOM_DOMAIN=your-domain.com
```

## **部署步骤**

### 步骤 1: 准备环境

```bash
# 1. 安装 Google Cloud CLI
# 下载: https://cloud.google.com/sdk/docs/install

# 2. 认证
gcloud auth login

# 3. 设置项目
gcloud config set project YOUR_PROJECT_ID
```

### 步骤 2: 设置环境变量

```bash
# 设置必需的环境变量
export PROJECT_ID=your-project-id-here
export ALPHAGENOME_API_KEY=your-api-key-here

# 可选配置
export REGION=us-central1
export SERVICE_NAME=alphagenome-proxy
```

### 步骤 3: 运行部署

```bash
# 方法 1: 使用一键部署脚本
chmod +x deployment-package/deploy.sh
./deployment-package/deploy.sh

# 方法 2: 手动部署
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --set-env-vars ALPHAGENOME_API_KEY=$ALPHAGENOME_API_KEY
```

## **部署后信息**

### 服务访问信息

```bash
# 获取服务 URL
SERVICE_URL=$(gcloud run services describe alphagenome-proxy --region=us-central1 --format="value(status.url)")

echo " HTTP 服务: $SERVICE_URL"
echo " gRPC 端点: ${SERVICE_URL#https://}:443"
```

### 测试服务

```bash
# 健康检查
curl "$SERVICE_URL/health"

# gRPC 测试
python deployment-package/scripts/test-service.sh
```

## **成本信息**

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

## **安全考虑**

### 1. **API 密钥安全**
- 使用环境变量存储
- 不要提交到代码仓库
- 定期轮换密钥

### 2. **访问控制**
- 使用 IAM 角色控制访问
- 定期审查权限
- 启用审计日志

### 3. **网络安全**
- 使用 HTTPS 加密
- 配置 CORS 策略
- 考虑 VPC 网络隔离

## 🆘 **故障排除**

### 常见问题

1. **权限不足**
   ```bash
   # 检查权限
   gcloud projects get-iam-policy YOUR_PROJECT_ID
   
   # 添加权限
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="user:your-email@example.com" \
     --role="roles/run.admin"
   ```

2. **API 未启用**
   ```bash
   # 启用必要的 API
   gcloud services enable \
     cloudbuild.googleapis.com \
     run.googleapis.com \
     storage.googleapis.com
   ```

3. **构建失败**
   ```bash
   # 查看构建日志
   gcloud builds log BUILD_ID
   ```

4. **服务启动失败**
   ```bash
   # 查看服务日志
   gcloud logging read "resource.type=cloud_run_revision"
   ```

## 📞 **支持信息**

### 联系信息
- 📧 **邮箱**: your-email@example.com
- **文档**: [项目文档链接]
- 🐛 **Issues**: [GitHub Issues 链接]

### 紧急联系
- 🚨 **紧急问题**: [紧急联系方式]
- 💬 **即时聊天**: [Slack/Discord 链接]

## 📝 **部署确认清单**

部署完成后，请确认以下项目：

- [ ] 服务成功部署到 Cloud Run
- [ ] 服务 URL 可以访问
- [ ] 健康检查通过
- [ ] gRPC 连接正常
- [ ] API 密钥配置正确
- [ ] 日志记录正常
- [ ] 性能测试通过
- [ ] 成本监控设置
- [ ] 备份策略配置
- [ ] 监控告警设置

---

** 部署完成后，你的 AlphaGenome 代理服务就可以使用了！** 