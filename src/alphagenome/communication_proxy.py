import grpc
from concurrent import futures
import logging
import requests
import os
from google.protobuf.json_format import MessageToDict, ParseDict
from src.alphagenome.protos import dna_model_pb2, dna_model_service_pb2_grpc

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
JSON_SERVICE_BASE_URL = os.getenv("JSON_SERVICE_BASE_URL", "http://127.0.0.1:8000")
API_KEY = os.getenv("ALPHAGENOME_API_KEY", "")
API_KEY_HEADER = os.getenv("API_KEY_HEADER", "Authorization")  # Default to Authorization header
API_KEY_PREFIX = os.getenv("API_KEY_PREFIX", "Bearer ")  # Default to Bearer prefix

# Check API key configuration
if API_KEY:
    logger.info(f"API key configured, will be sent in {API_KEY_HEADER} header")
else:
    logger.warning("No API key configured. Set ALPHAGENOME_API_KEY environment variable if needed.")


def _get_headers():
    """Build request headers including API key"""
    headers = {
        'Content-Type': 'application/json',
    }
    
    if API_KEY:
        if API_KEY_HEADER == "Authorization":
            headers[API_KEY_HEADER] = f"{API_KEY_PREFIX}{API_KEY}"
        else:
            headers[API_KEY_HEADER] = API_KEY
    
    return headers


class CommunicationProxyServicer(dna_model_service_pb2_grpc.DnaModelServiceServicer):
    def PredictSequence(self, request_iterator, context):
        logging.info("Proxying streaming PredictSequence request")
        try:
            # Process each request from the client
            for request in request_iterator:
                request_dict = MessageToDict(request, preserving_proto_field_name=True)
                
                # Your screenshot shows this was previously pointing to /predict_variant, which is correct
                json_service_url = f"{JSON_SERVICE_BASE_URL}/predict_variant" 
                
                headers = _get_headers()
                response = requests.post(json_service_url, json=request_dict, headers=headers)
                response.raise_for_status()
                json_response_data = response.json()

                grpc_response = dna_model_pb2.PredictSequenceResponse()
                ParseDict(json_response_data, grpc_response)
                
                # Use yield to stream each response
                yield grpc_response
        except Exception as e:
            logging.error(f"Error in PredictSequence stream: {e}")
            context.set_details(f"Error in PredictSequence stream: {e}")
            context.set_code(grpc.StatusCode.INTERNAL)

    # --- Also need to replace this method ---
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
                json_response_data = response.json()

                grpc_response = dna_model_pb2.PredictIntervalResponse()
                ParseDict(json_response_data, grpc_response)

                # Use yield to stream each response
                yield grpc_response
        except Exception as e:
            logging.error(f"Error in PredictInterval stream: {e}")
            context.set_details(f"Error in PredictInterval stream: {e}")
            context.set_code(grpc.StatusCode.INTERNAL)

    def PredictVariant(self, request, context):
        try:
            json_payload = MessageToDict(request, preserving_proto_field_name=True)
            logger.info(f"Received gRPC PredictVariant request: {json_payload}")
        except Exception as e:
            logger.error(f"Failed to convert PredictVariant request to JSON: {e}")
            context.set_details(f"Request conversion error: {e}")
            context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
            return dna_model_pb2.PredictVariantResponse()

        try:
            headers = _get_headers()
            response = requests.post(
                f"{JSON_SERVICE_BASE_URL}/predict_variant",
                json=json_payload,
                headers=headers,
                timeout=10
            )
            response.raise_for_status()
            logger.info(f"Received HTTP PredictVariant response: {response.text}")
        except requests.RequestException as e:
            logger.error(f"HTTP request failed (PredictVariant): {e}")
            context.set_details(f"HTTP request error: {e}")
            context.set_code(grpc.StatusCode.UNAVAILABLE)
            return dna_model_pb2.PredictVariantResponse()

        try:
            json_data = response.json()
            grpc_response = dna_model_pb2.PredictVariantResponse()
            ParseDict(json_data, grpc_response)
            logger.info(f"Returning gRPC PredictVariant response: {json_data}")
            return grpc_response
        except Exception as e:
            logger.error(f"Failed to parse JSON to gRPC PredictVariant response: {e}")
            context.set_details(f"Response conversion error: {e}")
            context.set_code(grpc.StatusCode.INTERNAL)
            return dna_model_pb2.PredictVariantResponse()

    def ScoreInterval(self, request, context):
        try:
            json_payload = MessageToDict(request, preserving_proto_field_name=True)
            logger.info(f"Received gRPC ScoreInterval request: {json_payload}")
        except Exception as e:
            logger.error(f"Failed to convert ScoreInterval request to JSON: {e}")
            context.set_details(f"Request conversion error: {e}")
            context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
            return dna_model_pb2.ScoreIntervalResponse()

        try:
            headers = _get_headers()
            response = requests.post(
                f"{JSON_SERVICE_BASE_URL}/score_interval",
                json=json_payload,
                headers=headers,
                timeout=10
            )
            response.raise_for_status()
            logger.info(f"Received HTTP ScoreInterval response: {response.text}")
        except requests.RequestException as e:
            logger.error(f"HTTP request failed (ScoreInterval): {e}")
            context.set_details(f"HTTP request error: {e}")
            context.set_code(grpc.StatusCode.UNAVAILABLE)
            return dna_model_pb2.ScoreIntervalResponse()

        try:
            json_data = response.json()
            grpc_response = dna_model_pb2.ScoreIntervalResponse()
            ParseDict(json_data, grpc_response)
            logger.info(f"Returning gRPC ScoreInterval response: {json_data}")
            return grpc_response
        except Exception as e:
            logger.error(f"Failed to parse JSON to gRPC ScoreInterval response: {e}")
            context.set_details(f"Response conversion error: {e}")
            context.set_code(grpc.StatusCode.INTERNAL)
            return dna_model_pb2.ScoreIntervalResponse()

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    dna_model_service_pb2_grpc.add_DnaModelServiceServicer_to_server(CommunicationProxyServicer(), server)
    server.add_insecure_port('[::]:50051')
    logger.info("Starting gRPC Communication Proxy on port 50051...")
    server.start()
    server.wait_for_termination() 