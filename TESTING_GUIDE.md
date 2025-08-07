# Communication Proxy 测试指南

本文档介绍如何测试 `communication_proxy.py` 文件的功能。

## 测试方法概述

### 1. 单元测试
使用 pytest 或 absltest 运行自动化测试。

### 2. 手动测试
使用提供的测试脚本进行端到端测试。

### 3. 集成测试
测试 gRPC 服务器与 JSON 服务的集成。

## 运行单元测试

### 安装依赖
```bash
# 激活虚拟环境
source venv/bin/activate

# 安装测试依赖
pip install pytest pytest-mock
```

### 运行测试
```bash
# 运行所有测试
python -m pytest src/alphagenome/communication_proxy_test.py -v

# 运行特定测试类
python -m pytest src/alphagenome/communication_proxy_test.py::CommunicationProxyTest -v

# 运行特定测试方法
python -m pytest src/alphagenome/communication_proxy_test.py::CommunicationProxyTest::test_predict_sequence_streaming_success -v
```

## 配置 API Key

### 1. 环境变量配置
代理服务支持通过环境变量配置 API key：

```bash
# 设置 API key
export ALPHAGENOME_API_KEY=your_api_key_here

# 设置 JSON 服务地址
export JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com

# 可选：自定义 API key header
export API_KEY_HEADER=Authorization
export API_KEY_PREFIX=Bearer 
```

### 2. 使用配置文件
复制 `config_example.env` 为 `.env` 并修改：

```bash
cp config_example.env .env
# 编辑 .env 文件，填入你的 API key
```

## 运行手动测试

### 1. 启动测试脚本
```bash
# 激活虚拟环境
source venv/bin/activate

# 运行手动测试脚本
python test_communication_proxy_manual.py
```

这个脚本会：
- 启动一个模拟的 JSON 服务（端口 8000）
- 启动 gRPC 代理服务器
- 执行各种测试用例
- 显示测试结果

### 2. 测试内容
手动测试包括：
- `PredictVariant` 单次请求
- `ScoreInterval` 单次请求  
- `PredictSequence` 流式请求
- `PredictInterval` 流式请求

## 测试场景

### 正常情况测试
- 成功的 gRPC 请求转换为 JSON 请求
- JSON 响应正确转换为 gRPC 响应
- 流式请求正确处理多个请求
- 错误处理机制正常工作

### 异常情况测试
- HTTP 连接失败
- JSON 解析错误
- 服务端错误响应
- 超时情况

## 验证要点

### 1. 请求转换
- gRPC 请求正确转换为 JSON 格式
- 请求发送到正确的端点：
  - `/predict_variant` 用于 PredictSequence
  - `/predict_interval` 用于 PredictInterval
  - `/predict_variant` 用于 PredictVariant
  - `/score_interval` 用于 ScoreInterval

### 2. 响应转换
- JSON 响应正确转换为 gRPC 格式
- 流式响应正确使用 `yield` 返回
- 错误状态码正确设置

### 3. 日志记录
- 请求和响应都有适当的日志记录
- 错误情况有详细的错误日志

## 调试技巧

### 1. 查看日志
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

### 2. 使用 gRPC 调试工具
```bash
# 安装 grpcurl
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

# 列出服务
grpcurl -plaintext localhost:50051 list

# 调用方法
grpcurl -plaintext -d '{"sequence": "ATCGATCG"}' localhost:50051 alphagenome.DnaModelService/PredictVariant
```

### 3. 网络调试
```bash
# 使用 curl 测试 JSON 服务
curl -X POST http://localhost:8000/predict_variant \
  -H "Content-Type: application/json" \
  -d '{"sequence": "ATCGATCG", "model_name": "test_model"}'
```

## 常见问题

### 1. 导入错误
确保 Python 路径正确设置：
```python
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))
```

### 2. 端口冲突
如果端口被占用，修改 `JSON_SERVICE_BASE_URL` 或使用不同的端口。

### 3. 依赖问题
确保所有依赖都已安装：
```bash
pip install grpcio grpcio-tools protobuf requests flask
```

## 性能测试

### 1. 并发测试
```python
import threading
import time

def concurrent_test():
    # 创建多个线程同时发送请求
    threads = []
    for i in range(10):
        thread = threading.Thread(target=send_request, args=(i,))
        threads.append(thread)
        thread.start()
    
    for thread in threads:
        thread.join()
```

### 2. 压力测试
使用工具如 Apache Bench 或 wrk 进行压力测试：
```bash
# 使用 wrk 进行压力测试
wrk -t12 -c400 -d30s http://localhost:8000/predict_variant
```

## 测试报告

运行测试后，检查以下指标：
- 测试通过率
- 响应时间
- 错误率
- 内存使用情况
- CPU 使用情况

## 持续集成

建议在 CI/CD 流程中包含这些测试：
```yaml
# .github/workflows/test.yml
- name: Run Communication Proxy Tests
  run: |
    python -m pytest src/alphagenome/communication_proxy_test.py -v
    python test_communication_proxy_manual.py
``` 