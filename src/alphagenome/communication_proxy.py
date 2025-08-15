import grpc
from concurrent import futures
import logging
import requests
import os
import base64
import json
from google.protobuf.json_format import MessageToDict, ParseDict
from src.alphagenome.protos import dna_model_pb2, dna_model_service_pb2_grpc

# Configure logging first
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Try to import real AlphaGenome package
try:
    import alphagenome
    from alphagenome.models import dna_client
    from alphagenome.data import genome
    REAL_ALPHAGENOME_AVAILABLE = True
    logger.info("Real AlphaGenome package imported successfully")
except ImportError as e:
    REAL_ALPHAGENOME_AVAILABLE = False
    logger.warning(f"Real AlphaGenome package not available: {e}")

# Load environment variables
try:
    from dotenv import load_dotenv
    load_dotenv()
    logger.info("Environment variables loaded from .env file")
except ImportError:
    logger.warning("python-dotenv not available, using system environment variables")

# Configuration
JSON_SERVICE_BASE_URL = os.getenv("JSON_SERVICE_BASE_URL", "http://127.0.0.1:8000")
API_KEY = os.getenv("ALPHAGENOME_API_KEY", "")
API_KEY_HEADER = os.getenv("API_KEY_HEADER", "Authorization")
API_KEY_PREFIX = os.getenv("API_KEY_PREFIX", "Bearer ")

# Check API key configuration
if API_KEY:
    logger.info(f"API key configured, will be sent in {API_KEY_HEADER} header")
else:
    logger.warning("No API key configured. Set ALPHAGENOME_API_KEY environment variable if needed.")


def _get_headers(content_type='application/json'):
    """Build request headers including API key"""
    headers = {
        'Content-Type': content_type,
    }
    
    if API_KEY:
        if API_KEY_HEADER == "Authorization":
            headers[API_KEY_HEADER] = f"{API_KEY_PREFIX}{API_KEY}"
        else:
            headers[API_KEY_HEADER] = API_KEY
    
    return headers


def _handle_binary_response(response):
    """Handle binary responses including images and other binary data"""
    content_type = response.headers.get('content-type', '')
    
    # Check if response is binary data
    if any(binary_type in content_type.lower() for binary_type in [
        'image/', 'application/octet-stream', 'application/pdf', 
        'audio/', 'video/', 'application/zip', 'application/x-binary'
    ]):
        logger.info(f"Detected binary response with content-type: {content_type}")
        
        # Get binary data
        binary_data = response.content
        
        # Create a response structure that includes binary data
        response_data = {
            'content_type': content_type,
            'binary_data': base64.b64encode(binary_data).decode('utf-8'),
            'data_size': len(binary_data),
            'is_binary': True
        }
        
        return response_data
    else:
        # Handle JSON response
        try:
            return response.json()
        except json.JSONDecodeError:
            # If not JSON, treat as text
            return {
                'content_type': content_type,
                'text_data': response.text,
                'is_binary': False
            }


def _convert_binary_to_protobuf(response_data, grpc_response):
    """Convert binary response data to protobuf format"""
    if response_data.get('is_binary', False):
        # Handle binary data
        binary_data = base64.b64decode(response_data['binary_data'])
        
        # If the response has a Tensor field, use it for binary data
        if hasattr(grpc_response, 'data') and hasattr(grpc_response.data, 'array'):
            # Set binary data in tensor array
            grpc_response.data.array.data = binary_data
            grpc_response.data.array.data_type = 1  # UINT8 for binary data
        elif hasattr(grpc_response, 'track_data') and hasattr(grpc_response.track_data, 'array'):
            # Set binary data in track data array
            grpc_response.track_data.array.data = binary_data
            grpc_response.track_data.array.data_type = 1  # UINT8 for binary data
        else:
            # Create a generic binary response
            if hasattr(grpc_response, 'data'):
                grpc_response.data.array.data = binary_data
                grpc_response.data.array.data_type = 1
        
        logger.info(f"Converted binary data of size {len(binary_data)} bytes to protobuf")
    else:
        # Handle regular JSON data
        try:
            ParseDict(response_data, grpc_response)
        except Exception as e:
            logger.warning(f"Failed to parse response with ParseDict: {e}")
            logger.info(f"Response data: {response_data}")
            # Try to manually set the response fields based on response type
            if hasattr(grpc_response, 'reference_output') and 'reference_output' in response_data:
                grpc_response.reference_output.output_type = response_data['reference_output'].get('output_type', 1)
            elif hasattr(grpc_response, 'output') and 'output' in response_data:
                if 'interval_data' in response_data.get('output', {}):
                    # For ScoreInterval response
                    pass  # interval_data is already empty dict
                else:
                    # For PredictSequence and PredictInterval
                    grpc_response.output.output_type = response_data['output'].get('output_type', 1)


class CommunicationProxyServicer(dna_model_service_pb2_grpc.DnaModelServiceServicer):
    def PredictSequence(self, request_iterator, context):
        logging.info("Proxying streaming PredictSequence request")
        try:
            # Process each request from the client
            for request in request_iterator:
                request_dict = MessageToDict(request, preserving_proto_field_name=True)
                
                # Use predict_sequence endpoint for sequence prediction
                json_service_url = f"{JSON_SERVICE_BASE_URL}/predict_sequence"
                logger.info(f"PredictSequence calling endpoint: {json_service_url}") 
                
                headers = _get_headers()
                response = requests.post(json_service_url, json=request_dict, headers=headers)
                response.raise_for_status()
                
                # Handle response (binary or JSON)
                response_data = _handle_binary_response(response)
                logger.info(f"PredictSequence response data: {response_data}")

                grpc_response = dna_model_pb2.PredictSequenceResponse()
                _convert_binary_to_protobuf(response_data, grpc_response)
                
                # Use yield to stream each response
                yield grpc_response
        except Exception as e:
            logging.error(f"Error in PredictSequence stream: {e}")
            context.set_details(f"Error in PredictSequence stream: {e}")
            context.set_code(grpc.StatusCode.INTERNAL)

    def PredictInterval(self, request_iterator, context):
        logging.info("Proxying streaming PredictInterval request")
        try:
            # Process each request from the client
            for request in request_iterator:
                request_dict = MessageToDict(request, preserving_proto_field_name=True)
                json_service_url = f"{JSON_SERVICE_BASE_URL}/predict_interval"
                
                headers = _get_headers()
                response = requests.post(json_service_url, json=request_dict, headers=headers)
                response.raise_for_status()
                
                # Handle response (binary or JSON)
                response_data = _handle_binary_response(response)

                grpc_response = dna_model_pb2.PredictIntervalResponse()
                _convert_binary_to_protobuf(response_data, grpc_response)

                # Use yield to stream each response
                yield grpc_response
        except Exception as e:
            logging.error(f"Error in PredictInterval stream: {e}")
            context.set_details(f"Error in PredictInterval stream: {e}")
            context.set_code(grpc.StatusCode.INTERNAL)

    def PredictVariant(self, request_iterator, context):
        logging.info("Proxying streaming PredictVariant request")
        try:
            # Process each request from the client
            for request in request_iterator:
                try:
                    json_payload = MessageToDict(request, preserving_proto_field_name=True)
                    logger.info(f"Received gRPC PredictVariant request: {json_payload}")
                except Exception as e:
                    logger.error(f"Failed to convert PredictVariant request to JSON: {e}")
                    context.set_details(f"Request conversion error: {e}")
                    context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
                    continue

                try:
                    headers = _get_headers()
                    response = requests.post(
                        f"{JSON_SERVICE_BASE_URL}/predict_variant",
                        json=json_payload,
                        headers=headers,
                        timeout=10
                    )
                    response.raise_for_status()
                    logger.info(f"Received HTTP PredictVariant response with content-type: {response.headers.get('content-type', 'unknown')}")
                except requests.RequestException as e:
                    logger.error(f"HTTP request failed (PredictVariant): {e}")
                    context.set_details(f"HTTP request error: {e}")
                    context.set_code(grpc.StatusCode.UNAVAILABLE)
                    continue

                try:
                    # Handle response (binary or JSON)
                    response_data = _handle_binary_response(response)
                    
                    grpc_response = dna_model_pb2.PredictVariantResponse()
                    _convert_binary_to_protobuf(response_data, grpc_response)
                    
                    logger.info(f"Returning gRPC PredictVariant response")
                    yield grpc_response
                except Exception as e:
                    logger.error(f"Failed to parse response to gRPC PredictVariant response: {e}")
                    context.set_details(f"Response conversion error: {e}")
                    context.set_code(grpc.StatusCode.INTERNAL)
                    continue
        except Exception as e:
            logging.error(f"Error in PredictVariant stream: {e}")
            context.set_details(f"Error in PredictVariant stream: {e}")
            context.set_code(grpc.StatusCode.INTERNAL)

    def ScoreInterval(self, request_iterator, context):
        logging.info("Proxying streaming ScoreInterval request")
        try:
            # Process each request from the client
            for request in request_iterator:
                try:
                    json_payload = MessageToDict(request, preserving_proto_field_name=True)
                    logger.info(f"Received gRPC ScoreInterval request: {json_payload}")
                except Exception as e:
                    logger.error(f"Failed to convert ScoreInterval request to JSON: {e}")
                    context.set_details(f"Request conversion error: {e}")
                    context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
                    continue

                try:
                    headers = _get_headers()
                    response = requests.post(
                        f"{JSON_SERVICE_BASE_URL}/score_interval",
                        json=json_payload,
                        headers=headers,
                        timeout=10
                    )
                    response.raise_for_status()
                    logger.info(f"Received HTTP ScoreInterval response with content-type: {response.headers.get('content-type', 'unknown')}")
                except requests.RequestException as e:
                    logger.error(f"HTTP request failed (ScoreInterval): {e}")
                    context.set_details(f"HTTP request error: {e}")
                    context.set_code(grpc.StatusCode.UNAVAILABLE)
                    continue

                try:
                    # Handle response (binary or JSON)
                    response_data = _handle_binary_response(response)
                    
                    grpc_response = dna_model_pb2.ScoreIntervalResponse()
                    _convert_binary_to_protobuf(response_data, grpc_response)
                    
                    logger.info(f"Returning gRPC ScoreInterval response")
                    yield grpc_response
                except Exception as e:
                    logger.error(f"Failed to parse response to gRPC ScoreInterval response: {e}")
                    context.set_details(f"Response conversion error: {e}")
                    context.set_code(grpc.StatusCode.INTERNAL)
                    continue
        except Exception as e:
            logging.error(f"Error in ScoreInterval stream: {e}")
            context.set_details(f"Error in ScoreInterval stream: {e}")
            context.set_code(grpc.StatusCode.INTERNAL)

    def ScoreVariant(self, request_iterator, context):
        logging.info("Proxying streaming ScoreVariant request")
        try:
            for request in request_iterator:
                try:
                    json_payload = MessageToDict(request, preserving_proto_field_name=True)
                    logger.info(f"Received gRPC ScoreVariant request: {json_payload}")
                except Exception as e:
                    logger.error(f"Failed to convert ScoreVariant request to JSON: {e}")
                    context.set_details(f"Request conversion error: {e}")
                    context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
                    continue

                try:
                    headers = _get_headers()
                    response = requests.post(
                        f"{JSON_SERVICE_BASE_URL}/score_variant",
                        json=json_payload,
                        headers=headers,
                        timeout=10
                    )
                    response.raise_for_status()
                    logger.info(f"Received HTTP ScoreVariant response with content-type: {response.headers.get('content-type', 'unknown')}")
                except requests.RequestException as e:
                    logger.error(f"HTTP request failed (ScoreVariant): {e}")
                    context.set_details(f"HTTP request error: {e}")
                    context.set_code(grpc.StatusCode.UNAVAILABLE)
                    continue

                try:
                    response_data = _handle_binary_response(response)
                    grpc_response = dna_model_pb2.ScoreVariantResponse()
                    _convert_binary_to_protobuf(response_data, grpc_response)
                    logger.info("Returning gRPC ScoreVariant response")
                    yield grpc_response
                except Exception as e:
                    logger.error(f"Failed to parse response to gRPC ScoreVariant response: {e}")
                    context.set_details(f"Response conversion error: {e}")
                    context.set_code(grpc.StatusCode.INTERNAL)
                    continue
        except Exception as e:
            logging.error(f"Error in ScoreVariant stream: {e}")
            context.set_details(f"Error in ScoreVariant stream: {e}")
            context.set_code(grpc.StatusCode.INTERNAL)

    def ScoreIsmVariant(self, request_iterator, context):
        logging.info("Proxying streaming ScoreIsmVariant request")
        try:
            for request in request_iterator:
                try:
                    json_payload = MessageToDict(request, preserving_proto_field_name=True)
                    logger.info(f"Received gRPC ScoreIsmVariant request: {json_payload}")
                except Exception as e:
                    logger.error(f"Failed to convert ScoreIsmVariant request to JSON: {e}")
                    context.set_details(f"Request conversion error: {e}")
                    context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
                    continue

                try:
                    headers = _get_headers()
                    response = requests.post(
                        f"{JSON_SERVICE_BASE_URL}/score_ism_variant",
                        json=json_payload,
                        headers=headers,
                        timeout=10
                    )
                    response.raise_for_status()
                    logger.info(f"Received HTTP ScoreIsmVariant response with content-type: {response.headers.get('content-type', 'unknown')}")
                except requests.RequestException as e:
                    logger.error(f"HTTP request failed (ScoreIsmVariant): {e}")
                    context.set_details(f"HTTP request error: {e}")
                    context.set_code(grpc.StatusCode.UNAVAILABLE)
                    continue

                try:
                    response_data = _handle_binary_response(response)
                    grpc_response = dna_model_pb2.ScoreIsmVariantResponse()
                    _convert_binary_to_protobuf(response_data, grpc_response)
                    logger.info("Returning gRPC ScoreIsmVariant response")
                    yield grpc_response
                except Exception as e:
                    logger.error(f"Failed to parse response to gRPC ScoreIsmVariant response: {e}")
                    context.set_details(f"Response conversion error: {e}")
                    context.set_code(grpc.StatusCode.INTERNAL)
                    continue
        except Exception as e:
            logging.error(f"Error in ScoreIsmVariant stream: {e}")
            context.set_details(f"Error in ScoreIsmVariant stream: {e}")
            context.set_code(grpc.StatusCode.INTERNAL)

    def GetMetadata(self, request, context):
        logging.info("Proxying GetMetadata request")
        try:
            try:
                json_payload = MessageToDict(request, preserving_proto_field_name=True)
                logger.info(f"Received gRPC GetMetadata request: {json_payload}")
            except Exception as e:
                logger.error(f"Failed to convert GetMetadata request to JSON: {e}")
                context.set_details(f"Request conversion error: {e}")
                context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
                return

            headers = _get_headers()
            response = requests.post(
                f"{JSON_SERVICE_BASE_URL}/metadata",
                json=json_payload,
                headers=headers,
                timeout=10
            )
            response.raise_for_status()
            logger.info(f"Received HTTP GetMetadata response with content-type: {response.headers.get('content-type', 'unknown')}")

            response_data = _handle_binary_response(response)
            grpc_response = dna_model_pb2.MetadataResponse()
            _convert_binary_to_protobuf(response_data, grpc_response)
            yield grpc_response
        except requests.RequestException as e:
            logger.error(f"HTTP request failed (GetMetadata): {e}")
            context.set_details(f"HTTP request error: {e}")
            context.set_code(grpc.StatusCode.UNAVAILABLE)
        except Exception as e:
            logger.error(f"Failed to parse response to gRPC Metadata response: {e}")
            context.set_details(f"Response conversion error: {e}")
            context.set_code(grpc.StatusCode.INTERNAL)
def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    dna_model_service_pb2_grpc.add_DnaModelServiceServicer_to_server(CommunicationProxyServicer(), server)
    server.add_insecure_port('[::]:50051')
    logger.info("Starting gRPC Communication Proxy on port 50051...")
    server.start()
    server.wait_for_termination() 