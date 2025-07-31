# AlphaGenome 通信代理使用文档

## 📖 概述

AlphaGenome 通信代理是一个 gRPC 到 JSON 的代理服务，用于连接 AlphaGenome API。它提供了以下功能：

- **gRPC 接口**：提供标准的 gRPC 服务接口
- **JSON 转换**：自动转换 gRPC 请求到 JSON 格式
- **API Key 管理**：安全地处理 API 密钥
- **多平台部署**：支持 Docker、AWS、Google Cloud、Kubernetes

## 🚀 快速开始

### 1. 环境要求

- Python 3.10+
- Docker & Docker Compose
- API Key（从 [AlphaGenome](https://github.com/google-deepmind/alphagenome) 获取）

### 2. 安装和启动

```bash
# 克隆项目
git clone <your-repo-url>
cd alphagenome-main

# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/macOS
# 或
venv\Scripts\activate  # Windows

# 安装依赖
pip install -r requirements.txt

# 配置 API Key
export ALPHAGENOME_API_KEY=your_api_key_here

# 启动服务
docker-compose up -d
```

### 3. 验证服务

```bash
# 检查服务状态
docker-compose ps

# 运行测试
python -m pytest src/alphagenome/communication_proxy_test.py -v

# 端到端测试
python test_end_to_end.py
```

## 🔧 配置

### 环境变量

创建 `.env` 文件或设置环境变量：

```bash
# JSON 服务的基础 URL
JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com

# AlphaGenome API Key
ALPHAGENOME_API_KEY=your_api_key_here

# API Key 的请求头名称 (可选，默认为 Authorization)
API_KEY_HEADER=Authorization

# API Key 的前缀 (可选，默认为 "Bearer ")
API_KEY_PREFIX=Bearer
```

### Docker Compose 配置

```yaml
version: '3.8'

services:
  alphagenome-proxy:
    build: .
    ports:
      - "50051:50051"
    environment:
      - JSON_SERVICE_BASE_URL=${JSON_SERVICE_BASE_URL:-https://api.alphagenome.google.com}
      - ALPHAGENOME_API_KEY=${ALPHAGENOME_API_KEY:-}
      - API_KEY_HEADER=${API_KEY_HEADER:-Authorization}
      - API_KEY_PREFIX=${API_KEY_PREFIX:-Bearer }
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
```

## 📡 API 使用

### gRPC 客户端示例

```python
import grpc
from alphagenome.protos import dna_model_pb2, dna_model_service_pb2_grpc

# 连接到代理服务
channel = grpc.insecure_channel('localhost:50051')
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)

# 1. 预测变异
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

# 2. 评分区间
request = dna_model_pb2.ScoreIntervalRequest()
request.interval.chromosome = "chr22"
request.interval.start = 35677410
request.interval.end = 35678410
request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS

response = stub.ScoreInterval(request)
print(f"评分结果: {response}")

# 3. 流式预测序列
request = dna_model_pb2.PredictSequenceRequest()
request.model_version = "test_model"
request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS
request.sequence = "ATCGATCG"

responses = stub.PredictSequence(iter([request]))
for response in responses:
    print(f"序列预测: {response}")
    break
```

### 支持的 API 方法

| 方法 | 类型 | 描述 |
|------|------|------|
| `PredictVariant` | 非流式 | 预测基因组变异的影响 |
| `ScoreInterval` | 非流式 | 评分基因组区间 |
| `PredictSequence` | 流式 | 预测 DNA 序列 |
| `PredictInterval` | 流式 | 预测基因组区间 |

## 🐳 Docker 部署

### 本地 Docker

```bash
# 构建镜像
docker build -t alphagenome-proxy .

# 运行容器
docker run -d \
  --name alphagenome-proxy \
  -p 50051:50051 \
  -e ALPHAGENOME_API_KEY=your_api_key_here \
  -e JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com \
  alphagenome-proxy
```

### Docker Compose

```bash
# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f alphagenome-proxy

# 停止服务
docker-compose down
```

## ☁️ 云平台部署

### AWS 部署

```bash
# 使用 CloudFormation
aws cloudformation create-stack \
  --stack-name alphagenome-proxy \
  --template-body file://deploy/aws/cloudformation.yaml \
  --parameters ParameterKey=ApiKey,ParameterValue=your_api_key_here

# 或使用部署脚本
./scripts/deploy.sh aws
```

### Google Cloud 部署

```bash
# 使用 Cloud Run
gcloud run deploy alphagenome-proxy \
  --image gcr.io/your-project/alphagenome-proxy \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated

# 或使用部署脚本
./scripts/deploy.sh gcp
```

### Kubernetes 部署

```bash
# 应用配置
kubectl apply -f deploy/kubernetes/deployment.yaml

# 或使用部署脚本
./scripts/deploy.sh kubernetes
```

## 🧪 测试

### 单元测试

```bash
# 运行所有单元测试
python -m pytest src/alphagenome/communication_proxy_test.py -v

# 运行特定测试
python -m pytest src/alphagenome/communication_proxy_test.py::CommunicationProxyTest::test_predict_variant_success -v
```

### 端到端测试

```bash
# 启动测试环境
docker-compose up -d

# 运行端到端测试
python test_end_to_end.py

# 测试真实 API
python test_real_api.py
```

### 手动测试

```bash
# 健康检查
curl -X GET http://localhost:8000/health

# 测试 gRPC 连接
python -c "
import grpc
from alphagenome.protos import dna_model_service_pb2_grpc
channel = grpc.insecure_channel('localhost:50051')
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)
print('gRPC 连接成功')
"
```

## 🔍 监控和日志

### 查看日志

```bash
# Docker 日志
docker-compose logs -f alphagenome-proxy

# 应用日志
tail -f logs/alphagenome-proxy.log
```

### 健康检查

```bash
# 检查服务状态
docker-compose ps

# 检查健康状态
curl -X GET http://localhost:8000/health
```

### 性能监控

```bash
# 查看资源使用
docker stats alphagenome-main2-alphagenome-proxy-1

# 查看网络连接
netstat -an | grep 50051
```

## 🛠️ 故障排除

### 常见问题

#### 1. 服务无法启动

```bash
# 检查端口占用
lsof -i :50051

# 检查 Docker 状态
docker-compose ps
docker-compose logs alphagenome-proxy
```

#### 2. API Key 错误

```bash
# 验证环境变量
docker-compose exec alphagenome-proxy env | grep ALPHAGENOME_API_KEY

# 重新设置 API Key
export ALPHAGENOME_API_KEY=your_new_api_key_here
docker-compose restart alphagenome-proxy
```

#### 3. 网络连接问题

```bash
# 检查网络连接
curl -X GET https://api.alphagenome.google.com/health

# 检查代理配置
docker-compose exec alphagenome-proxy env | grep JSON_SERVICE_BASE_URL
```

#### 4. gRPC 连接失败

```bash
# 检查 gRPC 服务
grpcurl -plaintext localhost:50051 list

# 测试 gRPC 调用
grpcurl -plaintext -d '{}' localhost:50051 alphagenome.DnaModelService/PredictVariant
```

### 调试模式

```bash
# 启用调试日志
export LOG_LEVEL=DEBUG
docker-compose restart alphagenome-proxy

# 查看详细日志
docker-compose logs -f alphagenome-proxy
```

## 📚 高级配置

### 自定义请求头

```python
# 在代码中自定义请求头
def _get_headers():
    headers = {
        'Content-Type': 'application/json',
        'X-Custom-Header': 'custom-value'
    }
    
    if API_KEY:
        headers['Authorization'] = f"Bearer {API_KEY}"
    
    return headers
```

### 负载均衡

```yaml
# 使用多个代理实例
version: '3.8'
services:
  alphagenome-proxy-1:
    build: .
    ports:
      - "50051:50051"
    environment:
      - ALPHAGENOME_API_KEY=${ALPHAGENOME_API_KEY}
  
  alphagenome-proxy-2:
    build: .
    ports:
      - "50052:50051"
    environment:
      - ALPHAGENOME_API_KEY=${ALPHAGENOME_API_KEY}
```

### 缓存配置

```python
# 添加缓存支持
import redis
import json

redis_client = redis.Redis(host='localhost', port=6379, db=0)

def get_cached_response(request_key):
    cached = redis_client.get(request_key)
    if cached:
        return json.loads(cached)
    return None

def cache_response(request_key, response):
    redis_client.setex(request_key, 3600, json.dumps(response))
```

## 🔒 安全最佳实践

### API Key 安全

```bash
# 使用环境变量而不是硬编码
export ALPHAGENOME_API_KEY=your_api_key_here

# 使用密钥管理服务
# AWS Secrets Manager
aws secretsmanager get-secret-value --secret-id alphagenome-api-key

# Google Secret Manager
gcloud secrets versions access latest --secret="alphagenome-api-key"
```

### 网络安全

```yaml
# 限制网络访问
services:
  alphagenome-proxy:
    networks:
      - internal
    ports:
      - "127.0.0.1:50051:50051"  # 只允许本地访问

networks:
  internal:
    driver: bridge
```

### 日志安全

```python
# 避免记录敏感信息
import logging

def log_request(request_dict):
    # 移除敏感字段
    safe_request = request_dict.copy()
    if 'api_key' in safe_request:
        safe_request['api_key'] = '***'
    
    logging.info(f"Request: {safe_request}")
```

## 📞 支持和反馈

### 获取帮助

- **文档**：查看 `docs/` 目录
- **示例**：查看 `colabs/` 目录中的 Jupyter 笔记本
- **测试**：运行测试套件验证功能

### 报告问题

1. 检查日志文件
2. 运行诊断测试
3. 收集环境信息
4. 提交详细的问题报告

### 贡献

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 创建 Pull Request

---

## 📄 许可证

本项目遵循 Apache 2.0 许可证。详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

感谢 Google DeepMind 提供的 AlphaGenome API 和开源社区的支持。 