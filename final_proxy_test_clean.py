#!/usr/bin/env python3
"""
Final comprehensive test for AlphaGenome Proxy
"""

import grpc
import requests
import json
from google.protobuf.json_format import MessageToDict
from src.alphagenome.protos import dna_model_pb2, dna_model_service_pb2_grpc

def test_all_endpoints():
    """Test all proxy endpoints comprehensively"""
    print("=== AlphaGenome Proxy Final Test ===")

    # Check service status
    print("1. Checking Service Status:")
    try:
        response = requests.get("http://127.0.0.1:8000/docs", timeout=5)
        print("   JSON Service (FastAPI): Running on http://127.0.0.1:8000")
    except:
        print("   JSON Service (FastAPI): Not running")
        return False
    
    try:
        channel = grpc.insecure_channel('localhost:50051')
        grpc.channel_ready_future(channel).result(timeout=5)
        print("   gRPC Proxy: Running on localhost:50051")
    except:
        print("   gRPC Proxy: Not running")
        return False
    
    print()
    
    # Test gRPC proxy
    print("2. Testing gRPC Proxy Methods:")
    channel = grpc.insecure_channel('localhost:50051')
    stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)
    
    # Test PredictSequence
    print("   Testing PredictSequence...")
    try:
        request = dna_model_pb2.PredictSequenceRequest()
        request.sequence = "ATCG"
        responses = stub.PredictSequence(iter([request]))
        for response in responses:
            print(f"   [SUCCESS] PredictSequence: {response}")
            break
    except grpc.RpcError as e:
        print(f"   [FAILED] PredictSequence: {e.code()}: {e.details()}")
    
    # Test PredictInterval
    print("   Testing PredictInterval...")
    try:
        request = dna_model_pb2.PredictIntervalRequest()
        request.interval.chromosome = "chr1"
        request.interval.start = 0
        request.interval.end = 100
        responses = stub.PredictInterval(iter([request]))
        for response in responses:
            print(f"   [SUCCESS] PredictInterval: {response}")
            break
    except grpc.RpcError as e:
        print(f"   [FAILED] PredictInterval: {e.code()}: {e.details()}")
    
    # Test PredictVariant
    print("   Testing PredictVariant...")
    try:
        request = dna_model_pb2.PredictVariantRequest()
        request.interval.chromosome = "chr1"
        request.interval.start = 0
        request.interval.end = 100
        request.variant.chromosome = "chr1"
        request.variant.position = 50
        request.variant.reference_bases = "A"
        request.variant.alternate_bases = "T"
        responses = stub.PredictVariant(iter([request]))
        for response in responses:
            print(f"   [SUCCESS] PredictVariant: {response}")
            break
    except grpc.RpcError as e:
        print(f"   [FAILED] PredictVariant: {e.code()}: {e.details()}")
    
    # Test ScoreVariant
    print("   Testing ScoreVariant...")
    try:
        request = dna_model_pb2.ScoreVariantRequest()
        request.interval.chromosome = "chr1"
        request.interval.start = 0
        request.interval.end = 100
        request.variant.chromosome = "chr1"
        request.variant.position = 50
        request.variant.reference_bases = "A"
        request.variant.alternate_bases = "T"
        responses = stub.ScoreVariant(iter([request]))
        for response in responses:
            print(f"   [SUCCESS] ScoreVariant: {response}")
            break
    except grpc.RpcError as e:
        print(f"   [FAILED] ScoreVariant: {e.code()}: {e.details()}")

    # Test ScoreIsmVariant
    print("   Testing ScoreIsmVariant...")
    try:
        request = dna_model_pb2.ScoreIsmVariantRequest()
        request.interval.chromosome = "chr1"
        request.interval.start = 0
        request.interval.end = 100
        request.ism_interval.chromosome = "chr1"
        request.ism_interval.start = 10
        request.ism_interval.end = 20
        responses = stub.ScoreIsmVariant(iter([request]))
        for response in responses:
            print(f"   [SUCCESS] ScoreIsmVariant: {response}")
            break
    except grpc.RpcError as e:
        print(f"   [FAILED] ScoreIsmVariant: {e.code()}: {e.details()}")

    # Test GetMetadata
    print("   Testing GetMetadata...")
    try:
        request = dna_model_pb2.MetadataRequest()
        request.organism = 1
        responses = stub.GetMetadata(request)
        for response in responses:
            print(f"   [SUCCESS] GetMetadata: {response}")
            break
    except grpc.RpcError as e:
        print(f"   [FAILED] GetMetadata: {e.code()}: {e.details()}")
    
    # Test ScoreInterval
    print("   Testing ScoreInterval...")
    try:
        request = dna_model_pb2.ScoreIntervalRequest()
        request.interval.chromosome = "chr1"
        request.interval.start = 0
        request.interval.end = 100
        responses = stub.ScoreInterval(iter([request]))
        for response in responses:
            print(f"   [SUCCESS] ScoreInterval: {response}")
            break
    except grpc.RpcError as e:
        print(f"   [FAILED] ScoreInterval: {e.code()}: {e.details()}")
    
    print()
    
    # Test JSON service directly
    print("3. Testing JSON Service Directly:")
    base_url = "http://127.0.0.1:8000"
    test_data = {"test": "data"}
    
    endpoints = [
        "/predict_sequence",
        "/predict_interval", 
        "/predict_variant",
        "/score_interval",
        "/score_variant",
        "/score_ism_variant",
        "/metadata"
    ]
    
    for endpoint in endpoints:
        try:
            response = requests.post(f"{base_url}{endpoint}", json=test_data, timeout=5)
            print(f"   [SUCCESS] {endpoint}: {response.status_code} - {response.json()}")
        except Exception as e:
            print(f"   [FAILED] {endpoint}: Error - {e}")
    
    print()
    print("=== Test Complete ===")
    return True

if __name__ == "__main__":
    test_all_endpoints()
