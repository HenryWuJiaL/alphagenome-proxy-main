# AlphaGenome 通信代理 API 参考

## 📡 服务概述

AlphaGenome 通信代理提供 gRPC 服务接口，支持以下功能：

- **基因组变异预测**：预测 DNA 变异对基因功能的影响
- **区间评分**：评估基因组区间的功能重要性
- **序列预测**：预测 DNA 序列的功能特征
- **流式处理**：支持大规模数据的流式处理

## 🔌 连接信息

- **服务地址**: `localhost:50051`
- **协议**: gRPC
- **认证**: API Key (通过 Authorization header)

## 📋 API 方法

### 1. PredictVariant

预测基因组变异对基因功能的影响。

**请求类型**: 非流式

**请求参数**:
```protobuf
message PredictVariantRequest {
  Interval interval = 1;        // 基因组区间
  Variant variant = 2;          // 变异信息
  Organism organism = 3;        // 生物体类型
  repeated OutputType requested_outputs = 4;  // 请求的输出类型
  repeated OntologyTerm ontology_terms = 5;   // 本体术语
  string model_version = 6;     // 模型版本
}
```

**响应**:
```protobuf
message PredictVariantResponse {
  oneof payload {
    Output output = 1;          // 输出结果
    TensorChunk tensor_chunk = 2; // 张量数据块
  }
}
```

**示例**:
```python
import grpc
from alphagenome.protos import dna_model_pb2, dna_model_service_pb2_grpc

channel = grpc.insecure_channel('localhost:50051')
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)

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

### 2. ScoreInterval

评估基因组区间的功能重要性。

**请求类型**: 非流式

**请求参数**:
```protobuf
message ScoreIntervalRequest {
  Interval interval = 1;        // 基因组区间
  Organism organism = 2;        // 生物体类型
  repeated OutputType requested_outputs = 3;  // 请求的输出类型
  repeated OntologyTerm ontology_terms = 4;   // 本体术语
  string model_version = 5;     // 模型版本
}
```

**响应**:
```protobuf
message ScoreIntervalResponse {
  ScoreIntervalOutput interval_data = 1;  // 区间评分数据
}
```

**示例**:
```python
request = dna_model_pb2.ScoreIntervalRequest()
request.interval.chromosome = "chr22"
request.interval.start = 35677410
request.interval.end = 35678410
request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS

response = stub.ScoreInterval(request)
print(f"评分结果: {response}")
```

### 3. PredictSequence

预测 DNA 序列的功能特征。

**请求类型**: 流式

**请求参数**:
```protobuf
message PredictSequenceRequest {
  string sequence = 1;          // DNA 序列
  Organism organism = 2;        // 生物体类型
  repeated OntologyTerm ontology_terms = 3;   // 本体术语
  repeated OutputType requested_outputs = 4;  // 请求的输出类型
  string model_version = 5;     // 模型版本
}
```

**响应**:
```protobuf
message PredictSequenceResponse {
  oneof payload {
    Output output = 1;          // 输出结果
    TensorChunk tensor_chunk = 2; // 张量数据块
  }
}
```

**示例**:
```python
request = dna_model_pb2.PredictSequenceRequest()
request.model_version = "test_model"
request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS
request.sequence = "ATCGATCG"

responses = stub.PredictSequence(iter([request]))
for response in responses:
    print(f"序列预测: {response}")
    break  # 只取第一个响应
```

### 4. PredictInterval

预测基因组区间的功能特征。

**请求类型**: 流式

**请求参数**:
```protobuf
message PredictIntervalRequest {
  Interval interval = 1;        // 基因组区间
  Organism organism = 2;        // 生物体类型
  repeated OutputType requested_outputs = 3;  // 请求的输出类型
  repeated OntologyTerm ontology_terms = 4;   // 本体术语
  string model_version = 5;     // 模型版本
}
```

**响应**:
```protobuf
message PredictIntervalResponse {
  oneof payload {
    Output output = 1;          // 输出结果
    TensorChunk tensor_chunk = 2; // 张量数据块
  }
}
```

**示例**:
```python
request = dna_model_pb2.PredictIntervalRequest()
request.interval.chromosome = "chr3"
request.interval.start = 3000
request.interval.end = 4000
request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS

responses = stub.PredictInterval(iter([request]))
for response in responses:
    print(f"区间预测: {response}")
    break  # 只取第一个响应
```

## 📊 数据类型

### Interval (基因组区间)

```protobuf
message Interval {
  string chromosome = 1;  // 染色体名称，如 "chr1"
  int64 start = 2;        // 0-based 起始位置
  int64 end = 3;          // 0-based 结束位置
  Strand strand = 4;      // 链方向
}
```

### Variant (基因组变异)

```protobuf
message Variant {
  string chromosome = 1;        // 染色体名称
  int64 position = 2;           // 1-based 变异位置
  string reference_bases = 3;   // 参考碱基
  string alternate_bases = 4;   // 替代碱基
}
```

### Organism (生物体类型)

```protobuf
enum Organism {
  ORGANISM_UNSPECIFIED = 0;     // 未指定
  ORGANISM_HOMO_SAPIENS = 9606; // 人类
  ORGANISM_MUS_MUSCULUS = 10090; // 小鼠
}
```

### OutputType (输出类型)

```protobuf
enum OutputType {
  OUTPUT_TYPE_UNSPECIFIED = 0;      // 未指定
  OUTPUT_TYPE_ATAC = 1;             // ATAC-seq
  OUTPUT_TYPE_CAGE = 2;             // CAGE
  OUTPUT_TYPE_DNASE = 3;            // DNase I
  OUTPUT_TYPE_RNA_SEQ = 4;          // RNA-seq
  OUTPUT_TYPE_CHIP_HISTONE = 5;     // ChIP-seq (组蛋白)
  OUTPUT_TYPE_CHIP_TF = 6;          // ChIP-seq (转录因子)
  OUTPUT_TYPE_SPLICE_SITES = 7;     // 剪接位点
  OUTPUT_TYPE_SPLICE_SITE_USAGE = 8; // 剪接位点使用
  OUTPUT_TYPE_SPLICE_JUNCTIONS = 9;  // 剪接连接
  OUTPUT_TYPE_CONTACT_MAPS = 11;     // 接触图
  OUTPUT_TYPE_PROCAP = 12;           // PRO-cap
}
```

## 🔐 认证

### API Key 配置

```bash
# 设置环境变量
export ALPHAGENOME_API_KEY=your_api_key_here

# 或在 Docker 中设置
docker run -e ALPHAGENOME_API_KEY=your_api_key_here ...
```

### 请求头格式

```
Authorization: Bearer your_api_key_here
```

## 📈 错误处理

### 常见错误码

| 错误码 | 描述 | 解决方案 |
|--------|------|----------|
| `UNAUTHENTICATED` | API Key 无效或缺失 | 检查 API Key 配置 |
| `INVALID_ARGUMENT` | 请求参数无效 | 检查请求参数格式 |
| `INTERNAL` | 服务器内部错误 | 查看日志，重试请求 |
| `UNAVAILABLE` | 服务不可用 | 检查服务状态，稍后重试 |

### 错误处理示例

```python
import grpc
from alphagenome.protos import dna_model_service_pb2_grpc

try:
    response = stub.PredictVariant(request)
except grpc.RpcError as e:
    if e.code() == grpc.StatusCode.UNAUTHENTICATED:
        print("API Key 错误，请检查配置")
    elif e.code() == grpc.StatusCode.INVALID_ARGUMENT:
        print("请求参数错误，请检查格式")
    elif e.code() == grpc.StatusCode.INTERNAL:
        print("服务器内部错误，请稍后重试")
    else:
        print(f"未知错误: {e}")
```

## 📊 性能优化

### 批量处理

```python
# 批量处理多个请求
requests = []
for i in range(10):
    request = dna_model_pb2.PredictVariantRequest()
    # ... 设置请求参数
    requests.append(request)

# 使用流式处理
responses = stub.PredictVariant(iter(requests))
for response in responses:
    print(f"结果: {response}")
```

### 连接池

```python
import grpc
from concurrent.futures import ThreadPoolExecutor

# 创建连接池
channel = grpc.insecure_channel(
    'localhost:50051',
    options=[
        ('grpc.max_send_message_length', 50 * 1024 * 1024),
        ('grpc.max_receive_message_length', 50 * 1024 * 1024),
    ]
)

# 使用线程池
with ThreadPoolExecutor(max_workers=10) as executor:
    futures = []
    for request in requests:
        future = executor.submit(stub.PredictVariant, request)
        futures.append(future)
    
    for future in futures:
        response = future.result()
        print(f"结果: {response}")
```

## 🔍 监控和调试

### 日志记录

```python
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 记录请求
logger.info(f"发送请求: {request}")

try:
    response = stub.PredictVariant(request)
    logger.info(f"收到响应: {response}")
except Exception as e:
    logger.error(f"请求失败: {e}")
```

### 性能监控

```python
import time

# 记录请求时间
start_time = time.time()
response = stub.PredictVariant(request)
end_time = time.time()

print(f"请求耗时: {end_time - start_time:.2f} 秒")
```

## 📚 完整示例

### 完整的客户端示例

```python
#!/usr/bin/env python3
"""
完整的 AlphaGenome 客户端示例
"""

import grpc
import time
import logging
from alphagenome.protos import dna_model_pb2, dna_model_service_pb2_grpc

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AlphaGenomeClient:
    def __init__(self, host='localhost', port=50051):
        self.channel = grpc.insecure_channel(f'{host}:{port}')
        self.stub = dna_model_service_pb2_grpc.DnaModelServiceStub(self.channel)
    
    def predict_variant(self, chromosome, position, ref_base, alt_base, 
                       start=None, end=None, organism=dna_model_pb2.ORGANISM_HOMO_SAPIENS):
        """预测变异影响"""
        request = dna_model_pb2.PredictVariantRequest()
        
        # 设置区间
        if start is None:
            start = position - 1000
        if end is None:
            end = position + 1000
            
        request.interval.chromosome = chromosome
        request.interval.start = start
        request.interval.end = end
        
        # 设置变异
        request.variant.chromosome = chromosome
        request.variant.position = position
        request.variant.reference_bases = ref_base
        request.variant.alternate_bases = alt_base
        request.organism = organism
        
        logger.info(f"预测变异: {chromosome}:{position} {ref_base}->{alt_base}")
        
        try:
            start_time = time.time()
            response = self.stub.PredictVariant(request)
            end_time = time.time()
            
            logger.info(f"预测完成，耗时: {end_time - start_time:.2f} 秒")
            return response
        except grpc.RpcError as e:
            logger.error(f"预测失败: {e}")
            raise
    
    def score_interval(self, chromosome, start, end, 
                      organism=dna_model_pb2.ORGANISM_HOMO_SAPIENS):
        """评分区间"""
        request = dna_model_pb2.ScoreIntervalRequest()
        request.interval.chromosome = chromosome
        request.interval.start = start
        request.interval.end = end
        request.organism = organism
        
        logger.info(f"评分区间: {chromosome}:{start}-{end}")
        
        try:
            response = self.stub.ScoreInterval(request)
            return response
        except grpc.RpcError as e:
            logger.error(f"评分失败: {e}")
            raise
    
    def close(self):
        """关闭连接"""
        self.channel.close()

# 使用示例
if __name__ == '__main__':
    client = AlphaGenomeClient()
    
    try:
        # 预测变异
        variant_result = client.predict_variant(
            chromosome="chr22",
            position=36201698,
            ref_base="A",
            alt_base="C"
        )
        print(f"变异预测结果: {variant_result}")
        
        # 评分区间
        interval_result = client.score_interval(
            chromosome="chr22",
            start=35677410,
            end=35678410
        )
        print(f"区间评分结果: {interval_result}")
        
    finally:
        client.close()
```

---

## 📞 支持

如有问题，请参考：
- [用户指南](USER_GUIDE.md)
- [快速入门](QUICK_START.md)
- [故障排除](USER_GUIDE.md#故障排除) 