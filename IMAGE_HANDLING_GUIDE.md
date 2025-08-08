# Image and Binary Data Handling Guide

## Overview

The AlphaGenome proxy service has been enhanced to handle various types of responses including images, PDFs, and other binary data. This guide explains how the proxy processes and forwards binary data between the gRPC client and the JSON backend service.

## Supported Binary Data Types

The proxy automatically detects and handles the following content types:

### Images
- `image/png` - PNG images
- `image/jpeg` - JPEG images
- `image/gif` - GIF images
- `image/webp` - WebP images
- `image/svg+xml` - SVG images

### Documents
- `application/pdf` - PDF documents
- `application/octet-stream` - Generic binary data
- `application/zip` - ZIP archives
- `application/x-binary` - Custom binary formats

### Media
- `audio/*` - Audio files
- `video/*` - Video files

## How It Works

### 1. Request Flow

```
Client (gRPC) → Proxy → Backend (JSON API)
```

1. **Client sends gRPC request** with protobuf data
2. **Proxy converts** gRPC request to JSON
3. **Proxy forwards** JSON request to backend service
4. **Backend responds** with JSON or binary data
5. **Proxy detects** response type and processes accordingly
6. **Proxy converts** response back to gRPC format
7. **Client receives** gRPC response with binary data

### 2. Binary Data Detection

The proxy uses content-type headers to detect binary responses:

```python
def _handle_binary_response(response):
    content_type = response.headers.get('content-type', '')
    
    # Check if response is binary data
    if any(binary_type in content_type.lower() for binary_type in [
        'image/', 'application/octet-stream', 'application/pdf', 
        'audio/', 'video/', 'application/zip', 'application/x-binary'
    ]):
        # Handle as binary data
        return {
            'content_type': content_type,
            'binary_data': base64.b64encode(response.content).decode('utf-8'),
            'data_size': len(response.content),
            'is_binary': True
        }
    else:
        # Handle as JSON
        return response.json()
```

### 3. Protobuf Conversion

Binary data is stored in protobuf `bytes` fields:

```python
def _convert_binary_to_protobuf(response_data, grpc_response):
    if response_data.get('is_binary', False):
        binary_data = base64.b64decode(response_data['binary_data'])
        
        # Store in appropriate protobuf field
        if hasattr(grpc_response, 'data') and hasattr(grpc_response.data, 'array'):
            grpc_response.data.array.data = binary_data
            grpc_response.data.array.data_type = 1  # UINT8 for binary data
```

## Usage Examples

### 1. Basic Image Request

```python
import grpc
from src.alphagenome.protos import dna_model_service_pb2_grpc, dna_model_pb2

# Connect to proxy
channel = grpc.insecure_channel('localhost:50051')
stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)

# Create request
request = dna_model_pb2.PredictVariantRequest()
request.interval.chromosome = "chr22"
request.interval.start = 35677410
request.interval.end = 36725986
request.variant.chromosome = "chr22"
request.variant.position = 36201698
request.variant.reference_bases = "A"
request.variant.alternate_bases = "C"
request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS

# Send request
response = stub.PredictVariant(request)

# Check for binary data
if hasattr(response, 'data') and hasattr(response.data, 'array') and response.data.array.data:
    # Extract image data
    image_data = response.data.array.data
    
    # Save image
    with open('received_image.png', 'wb') as f:
        f.write(image_data)
    print("Image saved successfully!")
```

### 2. Image Processing with PIL

```python
from PIL import Image
import io

# Extract and process image
if hasattr(response, 'data') and hasattr(response.data, 'array') and response.data.array.data:
    image_data = response.data.array.data
    
    # Open with PIL
    image = Image.open(io.BytesIO(image_data))
    print(f"Image format: {image.format}")
    print(f"Image size: {image.size}")
    
    # Process image
    resized_image = image.resize((800, 600))
    resized_image.save('processed_image.png')
```

### 3. Multiple Response Types

```python
def handle_response(response):
    """Handle different types of responses"""
    
    # Check for binary data in data field
    if hasattr(response, 'data') and hasattr(response.data, 'array') and response.data.array.data:
        binary_data = response.data.array.data
        return handle_binary_data(binary_data, 'data')
    
    # Check for binary data in track_data field
    elif hasattr(response, 'track_data') and hasattr(response.track_data, 'array') and response.track_data.array.data:
        binary_data = response.track_data.array.data
        return handle_binary_data(binary_data, 'track_data')
    
    # Regular JSON response
    else:
        return handle_json_response(response)

def handle_binary_data(binary_data, field_name):
    """Handle binary data based on content type"""
    # Try to detect image
    try:
        image = Image.open(io.BytesIO(binary_data))
        return f"Image data in {field_name}: {image.format} {image.size}"
    except:
        # Not an image, treat as generic binary
        return f"Binary data in {field_name}: {len(binary_data)} bytes"
```

## Backend Service Implementation

### 1. Flask Backend with Image Support

```python
from flask import Flask, send_file, jsonify, request
from PIL import Image
import io

app = Flask(__name__)

@app.route('/predict_variant', methods=['POST'])
def predict_variant():
    # Check if client wants image response
    accept_header = request.headers.get('Accept', 'application/json')
    
    if 'image' in accept_header.lower():
        # Generate and return image
        img = generate_variant_visualization(request.json)
        img_io = io.BytesIO()
        img.save(img_io, 'PNG')
        img_io.seek(0)
        return send_file(img_io, mimetype='image/png')
    else:
        # Return JSON response
        return jsonify({
            'data': {
                'array': {
                    'data': base64.b64encode(b'Test data').decode('utf-8'),
                    'data_type': 1
                }
            }
        })

def generate_variant_visualization(request_data):
    """Generate visualization for variant data"""
    # Create a simple visualization
    img = Image.new('RGB', (800, 600), color='white')
    # Add visualization logic here
    return img
```

### 2. Express.js Backend with Image Support

```javascript
const express = require('express');
const app = express();

app.post('/predict_variant', (req, res) => {
    const acceptHeader = req.headers.accept || 'application/json';
    
    if (acceptHeader.includes('image')) {
        // Generate and return image
        const canvas = createCanvas(800, 600);
        const ctx = canvas.getContext('2d');
        
        // Draw visualization
        ctx.fillStyle = 'blue';
        ctx.fillRect(0, 0, 800, 600);
        
        // Convert to buffer
        const buffer = canvas.toBuffer('image/png');
        
        res.set('Content-Type', 'image/png');
        res.send(buffer);
    } else {
        // Return JSON response
        res.json({
            data: {
                array: {
                    data: Buffer.from('Test data').toString('base64'),
                    data_type: 1
                }
            }
        });
    }
});
```

## Testing

### 1. Run the Test Script

```bash
# Install dependencies
pip install pillow

# Run test
python test_image_handling.py
```

### 2. Manual Testing

```bash
# Start proxy service
python -m src.alphagenome.communication_proxy

# In another terminal, test with curl
curl -X POST http://localhost:8000/predict_variant \
  -H "Content-Type: application/json" \
  -H "Accept: image/png" \
  -d '{"interval": {"chromosome": "chr22"}}' \
  --output test_image.png
```

## Performance Considerations

### 1. Memory Usage

- Large images can consume significant memory
- Consider implementing streaming for very large files
- Monitor memory usage in production

### 2. Network Bandwidth

- Binary data increases network usage
- Consider compression for large files
- Implement caching for frequently requested images

### 3. Processing Time

- Image processing can be CPU-intensive
- Consider async processing for complex visualizations
- Implement timeouts for long-running operations

## Error Handling

### 1. Invalid Binary Data

```python
try:
    image_data = response.data.array.data
    image = Image.open(io.BytesIO(image_data))
except Exception as e:
    print(f"Error processing image: {e}")
    # Handle gracefully
```

### 2. Missing Data Fields

```python
def safe_extract_binary_data(response):
    """Safely extract binary data from response"""
    try:
        if hasattr(response, 'data') and hasattr(response.data, 'array'):
            return response.data.array.data
        elif hasattr(response, 'track_data') and hasattr(response.track_data, 'array'):
            return response.track_data.array.data
        else:
            return None
    except Exception as e:
        print(f"Error extracting binary data: {e}")
        return None
```

### 3. Content Type Mismatch

```python
def validate_content_type(content_type, expected_type):
    """Validate content type matches expected type"""
    if expected_type not in content_type.lower():
        raise ValueError(f"Expected {expected_type}, got {content_type}")
```

## Best Practices

### 1. Content Type Validation

Always validate content types before processing:

```python
def is_image_content_type(content_type):
    """Check if content type is an image"""
    return content_type.startswith('image/')

def is_supported_binary_type(content_type):
    """Check if binary type is supported"""
    supported_types = [
        'image/', 'application/pdf', 'application/octet-stream'
    ]
    return any(t in content_type.lower() for t in supported_types)
```

### 2. Error Recovery

Implement graceful error recovery:

```python
def process_response_with_fallback(response):
    """Process response with fallback options"""
    try:
        # Try primary processing method
        return process_binary_data(response)
    except Exception as e:
        print(f"Primary processing failed: {e}")
        try:
            # Try fallback method
            return process_as_text(response)
        except Exception as e2:
            print(f"Fallback processing failed: {e2}")
            return None
```

### 3. Logging

Add comprehensive logging for debugging:

```python
import logging

logger = logging.getLogger(__name__)

def log_binary_processing(content_type, data_size):
    """Log binary data processing"""
    logger.info(f"Processing binary data: {content_type}, size: {data_size} bytes")
```

## Troubleshooting

### Common Issues

1. **Image not displaying correctly**
   - Check content type headers
   - Verify binary data integrity
   - Ensure proper encoding/decoding

2. **Memory errors with large images**
   - Implement streaming
   - Add memory limits
   - Use image compression

3. **Performance issues**
   - Monitor response times
   - Implement caching
   - Consider async processing

### Debug Commands

```bash
# Check proxy logs
tail -f proxy.log

# Test with different content types
curl -H "Accept: image/png" http://localhost:8000/predict_variant
curl -H "Accept: application/json" http://localhost:8000/predict_variant

# Monitor network traffic
tcpdump -i lo0 port 50051
```

## Conclusion

The enhanced proxy service now supports comprehensive binary data handling, including images, PDFs, and other binary formats. This enables rich visualizations and data exchange while maintaining the performance benefits of the gRPC interface.

For additional support or questions about binary data handling, refer to the project documentation or create an issue in the repository.
