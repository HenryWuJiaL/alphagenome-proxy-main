# AlphaGenome 通信代理 - 快速入门

## 🚀 5分钟快速开始

### 1. 准备环境

```bash
# 确保已安装 Docker
docker --version
docker-compose --version

# 克隆项目（如果还没有）
cd alphagenome-main
```

### 2. 配置 API Key

```bash
# 设置你的 API Key
export ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw
```

### 3. 启动服务

```bash
# 一键启动
docker-compose up -d

# 检查状态
docker-compose ps
```

### 4. 测试连接

```bash
# 运行端到端测试
python test_end_to_end.py
```

### 5. 使用服务

```python
import grpc
from alphagenome.protos import dna_model_pb2, dna_model_service_pb2_grpc

# 连接
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

## 📋 常用命令

| 命令 | 描述 |
|------|------|
| `docker-compose up -d` | 启动服务 |
| `docker-compose down` | 停止服务 |
| `docker-compose logs -f` | 查看日志 |
| `docker-compose ps` | 检查状态 |
| `python test_end_to_end.py` | 运行测试 |

## 🔧 配置选项

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

## 🧪 验证安装

### 1. 服务状态检查

```bash
docker-compose ps
```

应该看到：
```
NAME                                    STATUS
alphagenome-main2-alphagenome-proxy-1   Up (healthy)
alphagenome-main2-mock-json-service-1   Up
```

### 2. 功能测试

```bash
# 单元测试
python -m pytest src/alphagenome/communication_proxy_test.py -v

# 端到端测试
python test_end_to_end.py
```

### 3. 手动测试

```bash
# 健康检查
curl -X GET http://localhost:8000/health

# gRPC 连接测试
python -c "
import grpc
from alphagenome.protos import dna_model_service_pb2_grpc
channel = grpc.insecure_channel('localhost:50051')
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)
print('✅ gRPC 连接成功')
"
```

## 🛠️ 故障排除

### 常见问题

**Q: 服务启动失败**
```bash
# 检查端口占用
lsof -i :50051

# 查看错误日志
docker-compose logs alphagenome-proxy
```

**Q: API Key 错误**
```bash
# 验证环境变量
docker-compose exec alphagenome-proxy env | grep ALPHAGENOME_API_KEY

# 重新设置
export ALPHAGENOME_API_KEY=your_api_key_here
docker-compose restart alphagenome-proxy
```

**Q: 测试失败**
```bash
# 检查服务状态
docker-compose ps

# 查看详细日志
docker-compose logs -f
```

## 📚 下一步

- 查看完整文档：[USER_GUIDE.md](USER_GUIDE.md)
- 了解部署选项：[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- 查看测试指南：[TESTING_GUIDE.md](TESTING_GUIDE.md)

## 🆘 需要帮助？

1. 检查日志：`docker-compose logs -f`
2. 运行测试：`python test_end_to_end.py`
3. 查看文档：[USER_GUIDE.md](USER_GUIDE.md)

---

**🎉 恭喜！你的 AlphaGenome 通信代理已经成功运行！** 