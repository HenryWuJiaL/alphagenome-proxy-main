# 📋 客户信息收集模板

## 🎯 **请填写以下信息**

### 基本信息

**项目信息：**
- [ ] 项目 ID: `_________________`
- [ ] 项目名称: `_________________`
- [ ] 部署区域: `us-central1` (默认) 或 `_________________`

**API 密钥：**
- [ ] AlphaGenome API 密钥: `_________________`

### 访问权限（选择一种方式）

#### 方式 A: 给我项目访问权限（推荐）

**我的邮箱地址：** `deployer@example.com`

**你需要运行的命令：**
```bash
# 1. 设置项目
gcloud config set project YOUR_PROJECT_ID

# 2. 给我访问权限
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

**确认：**
- [ ] 已运行上述命令
- [ ] 权限添加成功

#### 方式 B: 创建服务账号并下载密钥

**你需要运行的命令：**
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
```

**确认：**
- [ ] 已运行上述命令
- [ ] 已下载 `deployment-key.json` 文件
- [ ] 服务账号邮箱: `deployment-helper@YOUR_PROJECT_ID.iam.gserviceaccount.com`

### 服务配置（可选）

**资源限制：**
- [ ] 内存: `512Mi` (默认) 或 `_________________`
- [ ] CPU: `1` (默认) 或 `_________________`
- [ ] 最大实例数: `10` (默认) 或 `_________________`

**网络配置：**
- [ ] 允许未认证访问: `是` (默认)
- [ ] 自定义域名: `_________________` (可选)

### 联系信息

**你的联系信息：**
- [ ] 邮箱: `_________________`
- [ ] 即时聊天: `_________________` (可选)

**部署偏好：**
- [ ] 部署时间: `_________________`
- [ ] 特殊要求: `_________________`

---

## 📧 **发送给我的信息**

请将填写好的信息发送给我：

### 如果选择方式 A：

```
项目信息：
- 项目 ID: [填写]
- 项目名称: [填写]
- 部署区域: [填写]

API 密钥：
- AlphaGenome API 密钥: [填写]

访问权限：
- 已添加用户: deployer@example.com
- 权限: Cloud Run 管理员、存储管理员、IAM 用户、Cloud Build 构建者

服务配置：
- 内存: [填写]
- CPU: [填写]
- 最大实例数: [填写]

联系信息：
- 邮箱: [填写]
```

### 如果选择方式 B：

```
项目信息：
- 项目 ID: [填写]
- 项目名称: [填写]
- 部署区域: [填写]

API 密钥：
- AlphaGenome API 密钥: [填写]

服务账号：
- 服务账号邮箱: [填写]
- 密钥文件: deployment-key.json（附件）

服务配置：
- 内存: [填写]
- CPU: [填写]
- 最大实例数: [填写]

联系信息：
- 邮箱: [填写]
```

---

## **安全承诺**

- 我只使用你提供的权限进行部署
- 我不会访问你的其他 Google Cloud 资源
- 部署完成后，你可以撤销我的访问权限
- 所有敏感信息通过安全渠道传输

## **成本说明**

- **免费额度**: 每月 200万请求
- **典型使用**: 几乎免费
- **超出免费额度**: 按使用付费

---

**填写完成后，我就可以帮你部署 AlphaGenome 代理服务了！** 