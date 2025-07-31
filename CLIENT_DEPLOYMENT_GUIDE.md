# 🚀 给客户的部署指南

## 📋 **你需要提供的信息**

### 1. **Google Cloud 项目信息** ⭐⭐⭐⭐⭐

```bash
# 你的项目 ID
PROJECT_ID=your-project-id-here

# 项目名称（可选）
PROJECT_NAME=your-project-name-here

# 部署区域（可选，默认 us-central1）
REGION=us-central1
```

**如何获取项目 ID：**
1. 登录 [Google Cloud Console](https://console.cloud.google.com/)
2. 在顶部导航栏查看项目 ID
3. 或运行：`gcloud projects list`

### 2. **AlphaGenome API 密钥** ⭐⭐⭐⭐⭐

```bash
# 你的 AlphaGenome API 密钥
ALPHAGENOME_API_KEY=your-api-key-here
```

**如何获取 API 密钥：**
1. 访问 [AlphaGenome Console](https://console.cloud.google.com/apis/credentials)
2. 创建新的 API 密钥
3. 复制密钥值

### 3. **访问权限** ⭐⭐⭐⭐⭐

选择以下一种方式：

#### 方式 A: 给我项目访问权限（推荐）

```bash
# 1. 安装 Google Cloud CLI（如果还没有）
# 下载: https://cloud.google.com/sdk/docs/install

# 2. 认证
gcloud auth login

# 3. 设置项目
gcloud config set project YOUR_PROJECT_ID

# 4. 给我访问权限（替换为我的邮箱）
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:deployer@example.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:deployer@example.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:deployer@example.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:deployer@example.com" \
  --role="roles/cloudbuild.builds.builder"
```

#### 方式 B: 创建服务账号并下载密钥

```bash
# 1. 创建服务账号
gcloud iam service-accounts create deployment-helper \
  --display-name="Deployment Helper"

# 2. 分配权限
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:deployment-helper@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:deployment-helper@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:deployment-helper@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:deployment-helper@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.builder"

# 3. 下载密钥文件
gcloud iam service-accounts keys create deployment-key.json \
  --iam-account=deployment-helper@YOUR_PROJECT_ID.iam.gserviceaccount.com

# 4. 把 deployment-key.json 文件发给我
```

## 📧 **你需要发给我的信息**

### 如果选择方式 A（推荐）

请发给我以下信息：

```
项目信息：
- 项目 ID: your-project-id-here
- 项目名称: your-project-name-here
- 部署区域: us-central1

API 密钥：
- AlphaGenome API 密钥: your-api-key-here

访问权限：
- 已添加用户: deployer@example.com
- 权限: Cloud Run 管理员、存储管理员、IAM 用户、Cloud Build 构建者
```

### 如果选择方式 B

请发给我以下信息：

```
项目信息：
- 项目 ID: your-project-id-here
- 项目名称: your-project-name-here
- 部署区域: us-central1

API 密钥：
- AlphaGenome API 密钥: your-api-key-here

服务账号：
- 服务账号邮箱: deployment-helper@your-project-id.iam.gserviceaccount.com
- 密钥文件: deployment-key.json（附件）
```

## 🔒 **安全说明**

### 权限说明
我需要的权限仅用于部署和管理服务：
- **Cloud Run 管理员**: 部署和管理服务
- **存储管理员**: 存储 Docker 镜像
- **IAM 用户**: 创建和管理服务账号
- **Cloud Build 构建者**: 构建 Docker 镜像

### 安全措施
- ✅ 我不会访问你的其他 Google Cloud 资源
- ✅ 部署完成后，你可以撤销我的访问权限
- ✅ API 密钥通过环境变量安全存储
- ✅ 所有通信使用 HTTPS 加密

## 💰 **成本说明**

### 免费额度（每月）
- **Cloud Run**: 200万请求
- **Cloud Build**: 120分钟构建时间
- **Container Registry**: 0.5GB 存储
- **网络**: 15GB 出站流量

### 典型使用成本
- **每月 10万请求**: 几乎免费
- **每月 100万请求**: 约 $5-10
- **每月 1000万请求**: 约 $50-100

## 🚀 **部署流程**

### 我帮你部署的步骤

1. **环境准备**
   - 验证项目访问权限
   - 启用必要的 Google Cloud API
   - 创建服务账号

2. **代码部署**
   - 构建 Docker 镜像
   - 部署到 Cloud Run
   - 配置环境变量

3. **测试验证**
   - 健康检查
   - gRPC 连接测试
   - 性能测试

4. **交付服务**
   - 提供服务 URL
   - 提供 gRPC 端点
   - 提供使用文档

## 📊 **部署后信息**

部署完成后，你会收到：

```
🎉 部署完成！

服务信息：
- HTTP URL: https://alphagenome-proxy-xxxxx-uc.a.run.app
- gRPC 端点: alphagenome-proxy-xxxxx-uc.a.run.app:443
- 健康检查: https://alphagenome-proxy-xxxxx-uc.a.run.app/health

管理命令：
- 查看日志: gcloud logging read 'resource.type=cloud_run_revision'
- 查看状态: gcloud run services describe alphagenome-proxy --region=us-central1
- 更新服务: gcloud run services update alphagenome-proxy --region=us-central1
- 删除服务: gcloud run services delete alphagenome-proxy --region=us-central1

使用示例：
- Python 客户端代码
- gRPC 调用示例
- 性能测试结果
```

## 🔧 **后续管理**

### 你可以自己管理服务

```bash
# 查看服务状态
gcloud run services describe alphagenome-proxy --region=us-central1

# 查看日志
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=alphagenome-proxy"

# 更新服务
gcloud run services update alphagenome-proxy --region=us-central1

# 删除服务
gcloud run services delete alphagenome-proxy --region=us-central1
```

### 撤销我的访问权限（可选）

```bash
# 如果选择方式 A，部署完成后可以撤销我的权限
gcloud projects remove-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:deployer@example.com" \
  --role="roles/run.admin"

gcloud projects remove-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:deployer@example.com" \
  --role="roles/storage.admin"

gcloud projects remove-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:deployer@example.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects remove-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:deployer@example.com" \
  --role="roles/cloudbuild.builds.builder"
```

## 📞 **联系信息**

如果你有任何问题：

- 📧 **邮箱**: deployer@example.com
- 💬 **即时聊天**: [Slack/Discord 链接]
- 📖 **文档**: [项目文档链接]

---

**准备好这些信息后，我就可以帮你部署 AlphaGenome 代理服务了！** 🚀 