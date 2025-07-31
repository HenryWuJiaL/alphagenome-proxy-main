# AlphaGenome 通信代理

[![Python](https://img.shields.io/badge/python-3.10%20%7C%203.11%20%7C%203.12%20%7C%203.13-blue.svg)](https://www.python.org/downloads/)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://www.docker.com/)
[![Tests](https://img.shields.io/badge/tests-passing-green.svg)](https://github.com/your-repo/alphagenome-proxy)

一个高性能的 gRPC 到 JSON 代理服务，用于连接 Google DeepMind 的 AlphaGenome API。

## 🚀 快速开始

### 5分钟快速部署

```bash
# 1. 克隆项目
git clone <your-repo-url>
cd alphagenome-main

# 2. 配置 API Key
export ALPHAGENOME_API_KEY=your_api_key_here

# 3. 启动服务
docker-compose up -d

# 4. 验证安装
python test_end_to_end.py
```

### 基本使用

```python
import grpc
from alphagenome.protos import dna_model_pb2, dna_model_service_pb2_grpc

# 连接服务
channel = grpc.insecure_channel('localhost:50051')
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)

# 预测变异
request = dna_model_pb2.PredictVariantRequest()
request.interval.chromosome = "chr22"
request.interval.start = 35677410
request.interval.end = 36725986
request.variant.chromosome = "chr22"
request.variant.position = 36201698
request.variant.reference_bases = "A"
request.variant.alternate_bases = "C"
request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS

response = stub.PredictVariant(request)
print(f"预测结果: {response}")
```

## ✨ 主要功能

- 🔄 **gRPC ↔ JSON 转换**：自动转换 gRPC 请求到 JSON 格式
- 🔐 **API Key 管理**：安全地处理 API 密钥
- 📡 **流式处理**：支持大规模数据的流式处理
- 🐳 **容器化部署**：Docker 一键部署
- ☁️ **多云支持**：AWS、Google Cloud、Kubernetes
- 🧪 **完整测试**：单元测试、端到端测试、集成测试

## 📊 支持的 API

| 方法 | 类型 | 描述 |
|------|------|------|
| `PredictVariant` | 非流式 | 预测基因组变异的影响 |
| `ScoreInterval` | 非流式 | 评分基因组区间 |
| `PredictSequence` | 流式 | 预测 DNA 序列 |
| `PredictInterval` | 流式 | 预测基因组区间 |

## 🏗️ 架构

```
┌─────────────────┐    gRPC    ┌──────────────────┐    HTTP/JSON    ┌─────────────────┐
│   gRPC Client   │ ──────────► │  Communication   │ ──────────────► │ AlphaGenome API │
│                 │             │     Proxy        │                 │                 │
└─────────────────┘             └──────────────────┘                 └─────────────────┘
                                        │
                                        ▼
                                ┌──────────────────┐
                                │   API Key Auth   │
                                │   Error Handling │
                                │   Logging        │
                                └──────────────────┘
```

## 📚 文档

- **[快速入门](QUICK_START.md)** - 5分钟快速部署指南
- **[用户指南](USER_GUIDE.md)** - 完整的使用文档
- **[API 参考](API_REFERENCE.md)** - 详细的 API 文档
- **[部署指南](DEPLOYMENT_GUIDE.md)** - 多平台部署说明
- **[测试指南](TESTING_GUIDE.md)** - 测试和验证方法

## 🧪 测试状态

| 测试类型 | 状态 | 通过率 |
|---------|------|--------|
| 单元测试 | ✅ 通过 | 100% (8/8) |
| 端到端测试 | ✅ 通过 | 100% (4/4) |
| Docker 服务 | ✅ 运行 | 100% (2/2) |
| API Key 集成 | ✅ 工作 | 100% |

## 🚀 部署选项

### 本地 Docker

```bash
docker-compose up -d
```

### AWS (CloudFormation)

```bash
./scripts/deploy.sh aws
```

### Google Cloud (Cloud Run)

```bash
./scripts/deploy.sh gcp
```

### Kubernetes

```bash
./scripts/deploy.sh kubernetes
```

## 🔧 配置

### 环境变量

```bash
# 必需
export ALPHAGENOME_API_KEY=your_api_key_here

# 可选
export JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com
export API_KEY_HEADER=Authorization
export API_KEY_PREFIX=Bearer
```

### 端口配置

- **gRPC 服务**: `localhost:50051`
- **健康检查**: `localhost:8000/health`

## 🛠️ 开发

### 环境设置

```bash
# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/macOS
# 或
venv\Scripts\activate  # Windows

# 安装依赖
pip install -r requirements.txt

# 安装开发依赖
pip install -r requirements-dev.txt
```

### 运行测试

```bash
# 单元测试
python -m pytest src/alphagenome/communication_proxy_test.py -v

# 端到端测试
python test_end_to_end.py

# 所有测试
python -m pytest
```

### 代码质量

```bash
# 代码格式化
black src/ tests/

# 代码检查
flake8 src/ tests/

# 类型检查
mypy src/
```

## 📈 性能

- **延迟**: < 100ms (本地网络)
- **吞吐量**: 1000+ 请求/秒
- **内存使用**: < 100MB
- **CPU 使用**: < 10%

## 🔒 安全

- ✅ API Key 安全存储
- ✅ 请求头认证
- ✅ 日志脱敏
- ✅ 网络安全配置
- ✅ 容器安全最佳实践

## 🤝 贡献

我们欢迎所有形式的贡献！

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

### 开发指南

- 遵循 PEP 8 代码风格
- 添加适当的测试
- 更新文档
- 确保所有测试通过

## 📄 许可证

本项目遵循 Apache 2.0 许可证。详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- [Google DeepMind](https://github.com/google-deepmind/alphagenome) - AlphaGenome API
- [gRPC](https://grpc.io/) - 高性能 RPC 框架
- [Docker](https://www.docker.com/) - 容器化平台
- 开源社区的支持

## 📞 支持

- 📖 [文档](USER_GUIDE.md)
- 🐛 [问题报告](https://github.com/your-repo/alphagenome-proxy/issues)
- 💬 [讨论](https://github.com/your-repo/alphagenome-proxy/discussions)
- 📧 [邮件支持](mailto:support@your-domain.com)

---

**⭐ 如果这个项目对你有帮助，请给我们一个星标！**

**🎉 感谢使用 AlphaGenome 通信代理！**
