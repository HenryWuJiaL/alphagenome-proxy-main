# AlphaGenome Web功能使用指南

## 快速开始

### 1. 启动服务

```bash
# 启动API服务
python3 start_services.py

# 在另一个终端启动Web服务器
python3 -m http.server 8080
```

### 2. 访问Web界面

打开浏览器访问: http://localhost:8080/web_interface.html

## Web界面功能

### 主界面 (web_interface.html)

#### 功能特性
- 🧬 **变体预测**: 预测基因变体的影响
- 📊 **变体评分**: 对变体进行评分
- 🎯 **区间预测**: 预测基因组区间的功能
- 📈 **区间评分**: 对区间进行评分
- 🔑 **API Key管理**: 安全的API密钥配置
- 🔍 **连接测试**: 测试与API服务的连接

#### 使用步骤

1. **配置API Key**
   - 在"API Key 配置"区域输入你的AlphaGenome API Key
   - 点击"保存 API Key"按钮

2. **选择预测方法**
   - 从下拉菜单选择预测方法:
     - `predict_variant`: 预测变体
     - `score_variant`: 评分变体
     - `predict_interval`: 预测区间
     - `score_interval`: 评分区间

3. **输入参数**
   - **染色体**: 例如 `chr22`
   - **起始位置**: 例如 `35677410`
   - **结束位置**: 例如 `36725986`
   - **变体位置**: 例如 `36201698`
   - **参考碱基**: 例如 `A`
   - **替代碱基**: 例如 `C`
   - **输出类型**: 选择RNA_SEQ、ATAC、DNASE或CAGE

4. **执行预测**
   - 点击"🚀 调用 AlphaGenome 预测"按钮
   - 等待预测结果（可能需要30-40秒）

5. **查看结果**
   - 预测结果会显示在页面底部
   - 包含预测数据和可视化图像

### 其他界面

#### 英文界面 (web_interface_english.html)
- 功能与主界面相同，但使用英文界面
- 适合国际用户使用

#### gRPC界面 (web_interface_grpc.html)
- 专门用于gRPC协议测试
- 包含gRPC特定的功能

#### 测试图像界面 (test_image.html)
- 用于测试图像生成功能
- 验证可视化组件

## API使用

### 基础端点

#### 健康检查
```bash
curl http://localhost:8000/health
```

#### 根端点
```bash
curl http://localhost:8000/
```

### 预测端点

#### 变体预测
```bash
curl -X POST http://localhost:8000/predict_variant \
  -H "Content-Type: application/json" \
  -d '{
    "interval": {
      "chromosome": "chr22",
      "start": 35677410,
      "end": 36725986
    },
    "variant": {
      "chromosome": "chr22",
      "position": 36201698,
      "reference_bases": "A",
      "alternate_bases": "C"
    },
    "organism": 9606,
    "requested_outputs": [4],
    "model_version": "v1"
  }'
```

#### 变体评分
```bash
curl -X POST http://localhost:8000/score_variant \
  -H "Content-Type: application/json" \
  -d '{
    "interval": {
      "chromosome": "chr22",
      "start": 35677410,
      "end": 36725986
    },
    "variant": {
      "chromosome": "chr22",
      "position": 36201698,
      "reference_bases": "A",
      "alternate_bases": "C"
    },
    "organism": 9606,
    "requested_outputs": [4],
    "model_version": "v1"
  }'
```

#### 区间预测
```bash
curl -X POST http://localhost:8000/predict_interval \
  -H "Content-Type: application/json" \
  -d '{
    "interval": {
      "chromosome": "chr22",
      "start": 35677410,
      "end": 36725986
    },
    "organism": 9606,
    "requested_outputs": [4],
    "model_version": "v1"
  }'
```

### 输出类型

| 代码 | 类型 | 说明 |
|------|------|------|
| 1 | ATAC | 染色质可及性 |
| 2 | CAGE | 基因表达 |
| 3 | DNASE | DNA酶敏感性 |
| 4 | RNA_SEQ | RNA测序 |

## 参数说明

### 必需参数

- **interval**: 基因组区间
  - `chromosome`: 染色体名称 (如 "chr22")
  - `start`: 起始位置
  - `end`: 结束位置

- **variant**: 基因变体 (仅变体相关端点)
  - `chromosome`: 染色体名称
  - `position`: 变体位置
  - `reference_bases`: 参考碱基
  - `alternate_bases`: 替代碱基

- **organism**: 生物体ID (9606 = 人类)
- **requested_outputs**: 输出类型列表
- **model_version**: 模型版本 ("v1")

### 可选参数

- **API Key**: 用于认证的API密钥

## 响应格式

### 成功响应
```json
{
  "status": "success",
  "message": "Real AlphaGenome prediction successful",
  "data_type": "<class 'alphagenome.models.dna_output.VariantOutput'>",
  "plot_image": "base64_encoded_image_data",
  "reference_output": {
    "output_type": 4,
    "variant_effect": "predicted",
    "prediction_confidence": 0.95,
    "model_version": "v1",
    "interval": {...},
    "variant": {...},
    "organism": 9606,
    "ontology_terms": [],
    "requested_outputs": [4]
  }
}
```

### 错误响应
```json
{
  "detail": "错误描述"
}
```

## 性能注意事项

### 响应时间
- 典型响应时间: 30-40秒
- 建议在web界面添加加载提示
- 考虑使用异步处理

### 并发限制
- 当前版本并发处理能力有限
- 建议单用户使用或限制并发请求数

### 资源使用
- 模型加载需要较多内存
- 建议在性能较好的机器上运行

## 故障排除

### 常见问题

1. **服务无法启动**
   - 检查端口是否被占用
   - 确认Python环境和依赖已正确安装

2. **API请求失败**
   - 检查服务是否正在运行
   - 验证请求格式是否正确
   - 确认API Key是否有效

3. **响应时间过长**
   - 这是正常现象，模型需要时间处理
   - 考虑优化请求参数

4. **Web界面无法访问**
   - 确认HTTP服务器已启动
   - 检查防火墙设置

### 调试技巧

1. **查看服务日志**
   ```bash
   # 查看API服务日志
   tail -f logs/api.log
   ```

2. **测试连接**
   ```bash
   # 测试健康检查
   curl http://localhost:8000/health
   ```

3. **检查端口**
   ```bash
   # 检查端口占用
   lsof -i :8000
   lsof -i :8080
   ```

## 高级功能

### 自定义参数
- 可以修改请求参数以适应不同的分析需求
- 支持多种染色体和基因组位置

### 批量处理
- 可以编写脚本进行批量预测
- 建议添加适当的延迟以避免过载

### 结果分析
- 预测结果包含详细的统计信息
- 可以进一步分析预测的可信度

## 联系支持

如果遇到问题，请：
1. 查看本文档的故障排除部分
2. 检查服务日志
3. 确认环境配置正确
4. 联系技术支持团队

---

*最后更新: 2025年8月20日*
