# AlphaGenome gRPC Proxy

A lightweight protocol translation proxy that converts gRPC requests to HTTP/JSON and vice versa for AlphaGenome services.

## Features

- Protocol conversion between gRPC and HTTP/JSON
- Streaming request/response support
- Binary data handling (images, audio, etc.)
- API key authentication
- Comprehensive error handling and logging
- Mock JSON service for testing

## Prerequisites

- Python 3.8+
- pip package manager

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/alphagenome-proxy.git
cd alphagenome-proxy
```

2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

## Quick Start

### 1. Start the Mock JSON Service

The mock service simulates the backend API responses:

```bash
uvicorn mock_json_service:app --reload --port 8000
```

This will start a FastAPI service on http://localhost:8000

### 2. Start the gRPC Proxy

In a new terminal:

```bash
python -c "from src.alphagenome.communication_proxy import serve; serve()"
```

This starts the gRPC proxy server on port 50051

### 3. Test the Setup

Run the comprehensive test:

```bash
python final_proxy_test.py
```

## Configuration

### Environment Variables

Set these environment variables before starting services:

```bash
export ALPHAGENOME_API_KEY="your_api_key_here"
export API_KEY_HEADER="Authorization"
export API_KEY_PREFIX="Bearer "
export JSON_SERVICE_BASE_URL="http://127.0.0.1:8000"
```

### API Key Configuration

The proxy supports flexible API key configuration:

- **Header Name**: Customize which HTTP header contains the API key
- **Prefix**: Add prefixes like "Bearer " or "API-Key "
- **Environment Variable**: Secure way to store sensitive keys

## Supported gRPC Methods

### 1. PredictSequence
Predicts genomic sequence characteristics.

```python
import grpc
from src.alphagenome.protos import dna_model_pb2, dna_model_service_pb2_grpc

channel = grpc.insecure_channel('localhost:50051')
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)

request = dna_model_pb2.PredictSequenceRequest()
request.sequence = "ATCGATCGATCG"
request.sequence_type = 1

responses = stub.PredictSequence(iter([request]))
for response in responses:
    print(f"Output type: {response.output.output_type}")
```

### 2. PredictInterval
Predicts characteristics for genomic intervals.

```python
request = dna_model_pb2.PredictIntervalRequest()
request.interval.chromosome = "chr1"
request.interval.start = 1000
request.interval.end = 2000

responses = stub.PredictInterval(iter([request]))
for response in responses:
    print(f"Output type: {response.output.output_type}")
```

### 3. PredictVariant
Predicts effects of genomic variants.

```python
request = dna_model_pb2.PredictVariantRequest()
request.interval.chromosome = "chr1"
request.interval.start = 1000
request.interval.end = 2000
request.variant.chromosome = "chr1"
request.variant.position = 1500
request.variant.reference_bases = "A"
request.variant.alternate_bases = "T"

responses = stub.PredictVariant(iter([request]))
for response in responses:
    print(f"Variant prediction: {response}")
```

### 4. ScoreInterval
Scores genomic intervals.

```python
request = dna_model_pb2.ScoreIntervalRequest()
request.interval.chromosome = "chr1"
request.interval.start = 1000
request.interval.end = 2000

responses = stub.ScoreInterval(iter([request]))
for response in responses:
    print(f"Interval score: {response}")
```

### 5. ScoreVariant
Scores genomic variants.

```python
request = dna_model_pb2.ScoreVariantRequest()
request.interval.chromosome = "chr1"
request.interval.start = 1000
request.interval.end = 2000
request.variant.chromosome = "chr1"
request.variant.position = 1500
request.variant.reference_bases = "A"
request.variant.alternate_bases = "T"

responses = stub.ScoreVariant(iter([request]))
for response in responses:
    print(f"Variant score: {response}")
```

### 6. ScoreIsmVariant
Scores ISM (In Silico Mutagenesis) variants.

```python
request = dna_model_pb2.ScoreIsmVariantRequest()
request.interval.chromosome = "chr1"
request.interval.start = 1000
request.interval.end = 2000
request.variant.chromosome = "chr1"
request.variant.position = 1500
request.variant.reference_bases = "A"
request.variant.alternate_bases = "T"

responses = stub.ScoreIsmVariant(iter([request]))
for response in responses:
    print(f"ISM variant score: {response}")
```

### 7. GetMetadata
Retrieves service metadata.

```python
request = dna_model_pb2.MetadataRequest()
request.model_name = "alphagenome_v1"

responses = stub.GetMetadata(request)
for response in responses:
    print(f"Metadata: {response}")
```

## Project Structure

```
src/alphagenome/
├── communication_proxy.py    # Main proxy implementation
├── alphagenome_types.py     # Type definitions
├── colab_utils.py           # Utility functions
├── tensor_utils.py          # Tensor operations
└── protos/                  # Protocol buffer definitions
    ├── dna_model_service.proto
    ├── dna_model.proto
    └── tensor.proto
```

## Development

### Adding New Endpoints

1. Add the endpoint to `mock_json_service.py`
2. Implement the corresponding gRPC method in `communication_proxy.py`
3. Add test cases to `final_proxy_test.py`

### Customizing Response Handling

Modify the `_convert_binary_to_protobuf` function in `communication_proxy.py` to handle custom response formats.

## Testing

### Basic Test
```bash
python test_proxy.py
```

### Comprehensive Test
```bash
python final_proxy_test.py
```

### Custom Test
```bash
python -c "
import grpc
from src.alphagenome.protos import dna_model_pb2, dna_model_service_pb2_grpc

channel = grpc.insecure_channel('localhost:50051')
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)

# Your custom test code here
"
```

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   lsof -nP -iTCP:8000 -sTCP:LISTEN | awk 'NR>1{print $2}' | xargs -r kill -9
   lsof -nP -iTCP:50051 -sTCP:LISTEN | awk 'NR>1{print $2}' | xargs -r kill -9
   ```

2. **Import Errors**
   - Ensure virtual environment is activated
   - Check that all dependencies are installed
   - Verify Python path includes src directory

3. **gRPC Connection Issues**
   - Verify proxy server is running on port 50051
   - Check firewall settings
   - Ensure correct channel address

### Logs

- Proxy logs: `/tmp/alphagenome_proxy.log`
- JSON service logs: `/tmp/alphagenome_json.log`

## Deployment

### Production Considerations

1. **Security**: Use HTTPS for JSON service
2. **Authentication**: Implement proper API key validation
3. **Monitoring**: Add health checks and metrics
4. **Scaling**: Use load balancers for multiple proxy instances

### Docker Deployment

```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 50051
CMD ["python", "-c", "from src.alphagenome.communication_proxy import serve; serve()"]
```



