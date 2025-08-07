# AlphaGenome Communication Proxy - Quick Start

## 5-Minute Quick Start

### 1. Prepare Environment

```bash
# Ensure Docker is installed
docker --version
docker-compose --version

# Clone project (if not already done)
cd alphagenome-main
```

### 2. Configure API Key

```bash
# Set your API Key
export ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw
```

### 3. Start Service

```bash
# One-click start
docker-compose up -d

# Check status
docker-compose ps
```

### 4. Test Connection

```bash
# Run end-to-end test
python test_end_to_end.py
```

### 5. Use Service

```python
import grpc
from alphagenome.protos import dna_model_pb2, dna_model_service_pb2_grpc

# Connect
channel = grpc.insecure_channel('localhost:50051')
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)

# Predict variant
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
print(f"Prediction result: {response}")
```

## Common Commands

| Command | Description |
|---------|-------------|
| `docker-compose up -d` | Start service |
| `docker-compose down` | Stop service |
| `docker-compose logs -f` | View logs |
| `docker-compose ps` | Check status |
| `python test_end_to_end.py` | Run tests |

## Configuration Options

### Environment Variables

```bash
# Required
export ALPHAGENOME_API_KEY=your_api_key_here

# Optional
export JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com
export API_KEY_HEADER=Authorization
export API_KEY_PREFIX=Bearer
```

### Port Configuration

- **gRPC Service**: `localhost:50051`
- **Health Check**: `localhost:8000/health`

## Verify Installation

### 1. Service Status Check

```bash
docker-compose ps
```

Should see:
```
NAME                                    STATUS
alphagenome-main2-alphagenome-proxy-1   Up (healthy)
alphagenome-main2-mock-json-service-1   Up
```

### 2. Functionality Test

```bash
# Unit tests
python -m pytest src/alphagenome/communication_proxy_test.py -v

# End-to-end test
python test_end_to_end.py
```

### 3. Manual Test

```bash
# Health check
curl -X GET http://localhost:8000/health

# gRPC connection test
python -c "
import grpc
from alphagenome.protos import dna_model_service_pb2_grpc
channel = grpc.insecure_channel('localhost:50051')
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)
print('gRPC connection successful')
"
```

## Troubleshooting

### Common Issues

**Q: Service fails to start**
```bash
# Check port usage
lsof -i :50051

# View error logs
docker-compose logs alphagenome-proxy
```

**Q: API Key error**
```bash
# Verify environment variables
docker-compose exec alphagenome-proxy env | grep ALPHAGENOME_API_KEY

# Reset
export ALPHAGENOME_API_KEY=your_api_key_here
docker-compose restart alphagenome-proxy
```

**Q: Test fails**
```bash
# Check service status
docker-compose ps

# View detailed logs
docker-compose logs -f
```

## Next Steps

- View complete documentation: [USER_GUIDE.md](USER_GUIDE.md)
- Learn about deployment options: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- Check testing guide: [TESTING_GUIDE.md](TESTING_GUIDE.md)

## Need Help?

1. Check logs: `docker-compose logs -f`
2. Run tests: `python test_end_to_end.py`
3. View documentation: [USER_GUIDE.md](USER_GUIDE.md)

---

**Congratulations! Your AlphaGenome Communication Proxy is successfully running!** 