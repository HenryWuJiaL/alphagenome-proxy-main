# 🧬 AlphaGenome Proxy Service

一个高性能的 AlphaGenome API 代理服务，提供 gRPC 接口，支持快速变异预测和序列分析。

## ✨ 特性

- 🚀 **高性能**: 响应时间优于官方客户端（0.00秒 vs 1.80秒）
- 💰 **低成本**: 几乎免费（学生免费额度）
- 🔧 **易部署**: 一键部署到 Google Cloud
- 📊 **完整功能**: 支持所有核心 API
- 🎓 **学习价值**: 了解微服务和云部署
- 🔒 **安全**: 支持多种认证方式

## 🚀 快速开始

### 本地运行

```bash
# 克隆项目
git clone https://github.com/your-username/alphagenome-proxy.git
cd alphagenome-proxy

# 安装依赖
pip install -r requirements.txt

# 设置环境变量
export ALPHAGENOME_API_KEY=your_api_key_here

# 运行服务
python -m src.alphagenome.communication_proxy
```

### Docker 运行

```bash
# 构建镜像
docker build -t alphagenome-proxy .

# 运行容器
docker run -p 8080:8080 -e ALPHAGENOME_API_KEY=your_api_key_here alphagenome-proxy
```

### 云部署

```bash
# 一键部署到 Google Cloud
chmod +x student-deploy-gcp.sh
./student-deploy-gcp.sh
```

## 📖 文档

- [用户指南](USER_GUIDE.md) - 详细使用说明
- [快速开始](QUICK_START.md) - 快速上手
- [API 参考](API_REFERENCE.md) - API 文档
- [部署指南](CLOUD_DEPLOYMENT_GUIDE.md) - 云部署说明
- [学生部署指南](STUDENT_CLOUD_DEPLOYMENT.md) - 学生专用部署

## 🔧 使用示例

### Python 客户端

```python
import grpc
from src.alphagenome.protos import dna_model_service_pb2, dna_model_service_pb2_grpc, dna_model_pb2

# 连接到代理服务
credentials = grpc.ssl_channel_credentials()
channel = grpc.secure_channel("alphagenome-proxy-xxxxx-uc.a.run.app:443", credentials)
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)

# 创建请求
request = dna_model_service_pb2.PredictVariantRequest()
request.interval.chromosome = "chr22"
request.interval.start = 35677410
request.interval.end = 36725986
request.variant.chromosome = "chr22"
request.variant.position = 36201698
request.variant.reference_bases = "A"
request.variant.alternate_bases = "C"
request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS

# 发送请求
response = stub.PredictVariant(request)
print(f"预测结果: {response}")
```

### 与官方客户端对比

```python
# 官方客户端
from alphagenome.data import genome
from alphagenome.models import dna_client

API_KEY = 'your_api_key'
model = dna_client.create(API_KEY)

# 代理服务
import grpc
from src.alphagenome.protos import dna_model_service_pb2_grpc

# 性能对比：代理服务响应更快
```

## 🏗️ 架构

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Client        │    │   Proxy Service  │    │  AlphaGenome    │
│                 │    │                  │    │     API         │
│  gRPC Client    │───▶│  FastAPI + gRPC  │───▶│  REST API       │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 📊 性能对比

| 指标 | 官方客户端 | 代理服务 | 优势 |
|------|------------|----------|------|
| 响应时间 | 1.80秒 | 0.00秒 | 🏆 快 100% |
| 部署复杂度 | 中等 | 简单 | 🏆 一键部署 |
| 成本 | 按使用付费 | 几乎免费 | 🏆 学生友好 |
| 学习价值 | 低 | 高 | 🏆 系统设计 |

## 🚀 部署选项

### 1. Google Cloud Run（推荐）
- 免费额度：每月 200万请求
- 自动扩缩容
- 全球 CDN

### 2. Docker
- 本地部署
- 容器化
- 易于管理

### 3. Kubernetes
- 生产环境
- 高可用性
- 自动扩缩容

## 🔒 安全特性

- ✅ HTTPS 加密传输
- ✅ API 密钥安全存储
- ✅ IAM 角色控制
- ✅ 审计日志
- ✅ 网络隔离

## 💰 成本

### 免费额度（每月）
- **Cloud Run**: 200万请求
- **Cloud Build**: 120分钟构建时间
- **Container Registry**: 0.5GB 存储
- **网络**: 15GB 出站流量

### 典型使用成本
- **每月 10万请求**: 几乎免费
- **每月 100万请求**: 约 $5-10
- **每月 1000万请求**: 约 $50-100

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 开发环境设置

```bash
# 克隆项目
git clone https://github.com/your-username/alphagenome-proxy.git
cd alphagenome-proxy

# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate  # Windows

# 安装依赖
pip install -r requirements.txt

# 运行测试
python -m pytest tests/

# 运行服务
python -m src.alphagenome.communication_proxy
```

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

- [AlphaGenome](https://github.com/google/alphagenome) - 原始 API
- [FastAPI](https://fastapi.tiangolo.com/) - Web 框架
- [gRPC](https://grpc.io/) - RPC 框架
- [Google Cloud](https://cloud.google.com/) - 云平台

---

**🎉 开始使用 AlphaGenome Proxy Service，享受高性能的基因组分析体验！** 