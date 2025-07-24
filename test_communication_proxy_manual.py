#!/usr/bin/env python3
"""
手动测试 communication_proxy.py 的脚本

使用方法:
1. 首先启动 JSON 服务 (模拟后端服务)
2. 然后运行这个脚本来测试 gRPC 代理
"""

import grpc
import time
import threading
from concurrent import futures
import requests
from flask import Flask, request, jsonify

# 导入 alphagenome 模块
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from alphagenome import communication_proxy
from alphagenome.protos import dna_model_pb2, dna_model_service_pb2_grpc


class MockJSONService:
    """模拟 JSON 服务"""
    
    def __init__(self, port=8000):
        self.app = Flask(__name__)
        self.port = port
        self.setup_routes()
    
    def setup_routes(self):
        @self.app.route('/predict_variant', methods=['POST'])
        def predict_variant():
            data = request.json
            print(f"收到 predict_variant 请求: {data}")
            return jsonify({
                "prediction": 0.85,
                "confidence": 0.92,
                "model_name": data.get("model_name", "default_model")
            })
        
        @self.app.route('/predict_interval', methods=['POST'])
        def predict_interval():
            data = request.json
            print(f"收到 predict_interval 请求: {data}")
            return jsonify({
                "score": 0.75,
                "region": f"{data.get('chromosome', 'chr1')}:{data.get('start', 0)}-{data.get('end', 1000)}"
            })
        
        @self.app.route('/score_interval', methods=['POST'])
        def score_interval():
            data = request.json
            print(f"收到 score_interval 请求: {data}")
            return jsonify({
                "score": 0.87,
                "region": f"{data.get('chromosome', 'chr1')}:{data.get('start', 0)}-{data.get('end', 1000)}"
            })
    
    def start(self):
        """启动模拟服务"""
        threading.Thread(target=self.app.run, kwargs={
            'host': '127.0.0.1',
            'port': self.port,
            'debug': False
        }, daemon=True).start()
        time.sleep(1)  # 等待服务启动
        print(f"模拟 JSON 服务已启动在端口 {self.port}")


def test_grpc_server():
    """测试 gRPC 服务器"""
    # 启动 gRPC 服务器
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    dna_model_service_pb2_grpc.add_DnaModelServiceServicer_to_server(
        communication_proxy.CommunicationProxyServicer(), server
    )
    port = server.add_insecure_port('[::]:0')
    server.start()
    print(f"gRPC 服务器已启动在端口 {port}")
    
    # 创建客户端
    channel = grpc.insecure_channel(f'localhost:{port}')
    stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)
    
    try:
        # 测试 PredictVariant
        print("\n=== 测试 PredictVariant ===")
        request = dna_model_pb2.PredictVariantRequest()
        request.chromosome = "chr1"
        request.position = 1000
        request.reference_allele = "A"
        request.alternate_allele = "T"
        request.model_name = "test_model"
        
        response = stub.PredictVariant(request)
        print(f"PredictVariant 响应: {response}")
        
        # 测试 ScoreInterval
        print("\n=== 测试 ScoreInterval ===")
        request = dna_model_pb2.ScoreIntervalRequest()
        request.chromosome = "chr1"
        request.start = 1000
        request.end = 2000
        
        response = stub.ScoreInterval(request)
        print(f"ScoreInterval 响应: {response}")
        
        # 测试 PredictSequence 流式请求
        print("\n=== 测试 PredictSequence 流式请求 ===")
        def generate_requests():
            for i in range(2):
                request = dna_model_pb2.PredictSequenceRequest()
                request.sequence = f"ATCGATCG{i}"
                request.model_name = "test_model"
                yield request
        
        responses = stub.PredictSequence(generate_requests())
        for i, response in enumerate(responses):
            print(f"PredictSequence 响应 {i+1}: {response}")
        
        # 测试 PredictInterval 流式请求
        print("\n=== 测试 PredictInterval 流式请求 ===")
        def generate_interval_requests():
            for i in range(2):
                request = dna_model_pb2.PredictIntervalRequest()
                request.chromosome = f"chr{i+1}"
                request.start = 1000 + i * 1000
                request.end = 2000 + i * 1000
                yield request
        
        responses = stub.PredictInterval(generate_interval_requests())
        for i, response in enumerate(responses):
            print(f"PredictInterval 响应 {i+1}: {response}")
            
    except Exception as e:
        print(f"测试过程中出现错误: {e}")
    finally:
        channel.close()
        server.stop(0)


def main():
    """主函数"""
    print("开始测试 communication_proxy.py")
    
    # 启动模拟 JSON 服务
    mock_service = MockJSONService()
    mock_service.start()
    
    # 等待一下确保服务完全启动
    time.sleep(2)
    
    # 测试 gRPC 服务器
    test_grpc_server()
    
    print("\n测试完成!")


if __name__ == "__main__":
    main() 