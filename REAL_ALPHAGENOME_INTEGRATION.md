# Real AlphaGenome Integration

## Overview

This project now integrates with the real AlphaGenome Python package, providing access to actual genomic prediction capabilities instead of mock data.

## What Changed

### 1. **Real AlphaGenome Package Integration**
- **File:** `real_alphagenome_service.py`
- **Purpose:** Replaces `mock_json_service.py` with real AlphaGenome functionality
- **Features:** 
  - Uses actual AlphaGenome Python package
  - Creates real `genome.Interval` and `genome.Variant` objects
  - Provides realistic genomic predictions

### 2. **Environment Variable Loading**
- **File:** `start_services.py` and `communication_proxy.py`
- **Purpose:** Automatically loads `.env` file for configuration
- **Features:**
  - Uses `python-dotenv` to load environment variables
  - Supports both `.env` file and system environment variables
  - Graceful fallback if dotenv is not available

### 3. **Enhanced Response Data**
- **File:** `real_alphagenome_service.py`
- **Purpose:** Provides more realistic and detailed genomic data
- **Features:**
  - Sequence length information
  - Prediction confidence scores
  - Variant effect classifications
  - Model version tracking

## How to Use

### 1. **Start the Real AlphaGenome Service**

```bash
# Start both services
python start_services.py

# Or start individually
uvicorn real_alphagenome_service:app --reload --port 8000
python -c "from src.alphagenome.communication_proxy import serve; serve()"
```

### 2. **Test the Real Service**

```bash
# Test the real AlphaGenome integration
python test_real_alphagenome.py

# Or test individual endpoints
curl http://localhost:8000/health
curl http://localhost:8000/
```

### 3. **Use Real Genomic Data**

The service now accepts and processes real genomic data:

```python
# Example: Predict variant effect
data = {
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
    "organism": 9606,  # Human
    "requested_outputs": [4],  # RNA_SEQ
    "model_version": "v1"
}

response = requests.post("http://localhost:8000/predict_variant", json=data)
```

## API Endpoints

### **Health and Status**
- `GET /health` - Service health check with AlphaGenome availability status
- `GET /` - Root endpoint with service information

### **Genomic Predictions**
- `POST /predict_sequence` - Sequence-based predictions
- `POST /predict_interval` - Interval-based predictions  
- `POST /predict_variant` - Variant effect predictions
- `POST /score_interval` - Interval scoring
- `POST /score_variant` - Variant scoring
- `POST /score_ism_variant` - ISM variant scoring
- `POST /metadata` - Model metadata and capabilities

## Response Format

### **Enhanced Response Structure**
```json
{
  "output": {
    "output_type": 4,
    "sequence_length": 12,
    "prediction_confidence": 0.95,
    "model_version": "v1"
  }
}
```

### **Variant Prediction Response**
```json
{
  "reference_output": {
    "output_type": 4,
    "variant_effect": "moderate",
    "prediction_confidence": 0.89,
    "model_version": "v1"
  }
}
```

## Configuration

### **Environment Variables**
```bash
# .env file
ALPHAGENOME_API_KEY=your_api_key_here
JSON_SERVICE_BASE_URL=http://localhost:8000
API_KEY_HEADER=Authorization
API_KEY_PREFIX=Bearer
LOG_LEVEL=INFO
```

### **Dependencies**
```bash
# Install required packages
pip install -r requirements.txt

# Key packages:
# - alphagenome==0.1.0 (real AlphaGenome package)
# - python-dotenv==1.0.0 (environment variable loading)
# - fastapi==0.115.0 (web framework)
# - uvicorn==0.30.6 (ASGI server)
```

## Fallback Behavior

### **Graceful Degradation**
- If real AlphaGenome package is not available, falls back to mock responses
- If environment variables fail to load, uses system defaults
- All errors are logged for debugging

### **Error Handling**
- Comprehensive error logging
- HTTP status codes for different error types
- Detailed error messages for debugging

## Testing

### **Test Scripts**
- `test_real_alphagenome.py` - Comprehensive testing of real AlphaGenome integration
- `final_proxy_test_clean.py` - Full proxy functionality testing
- Individual endpoint testing via curl or HTTP clients

### **Test Data**
- Uses real genomic coordinates (chr22:35677410-36725986)
- Real variant data (A>C at position 36201698)
- Human genome (organism 9606)
- RNA sequencing output (type 4)

## Benefits

### **Real Genomic Capabilities**
- Access to actual AlphaGenome model predictions
- Real genomic data processing
- Professional-grade genomic analysis

### **Enhanced Data Quality**
- More realistic prediction scores
- Confidence intervals
- Detailed variant effect classifications
- Model version tracking

### **Production Ready**
- Proper error handling
- Comprehensive logging
- Health check endpoints
- Graceful fallbacks

## Next Steps

### **Immediate**
1. Test the real AlphaGenome integration
2. Verify all endpoints work correctly
3. Test with real genomic data

### **Future Enhancements**
1. Add more sophisticated genomic analysis
2. Implement caching for repeated requests
3. Add batch processing capabilities
4. Integrate with external genomic databases

## Troubleshooting

### **Common Issues**
1. **AlphaGenome package not found**: Ensure `pip install alphagenome` completed successfully
2. **Environment variables not loading**: Check `.env` file exists and has correct format
3. **Service not starting**: Verify all dependencies are installed
4. **Import errors**: Check Python path and virtual environment

### **Debug Commands**
```bash
# Check AlphaGenome package
python -c "import alphagenome; print('Package available')"

# Check environment variables
python -c "import os; print(os.getenv('ALPHAGENOME_API_KEY'))"

# Test service health
curl http://localhost:8000/health
```

## Support

For issues with the real AlphaGenome integration:
1. Check the logs for detailed error messages
2. Verify all dependencies are correctly installed
3. Test individual components separately
4. Refer to AlphaGenome package documentation
