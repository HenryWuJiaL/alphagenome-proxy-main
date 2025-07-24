# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Tests for communication_proxy.py."""

import unittest
from unittest.mock import Mock, patch, MagicMock
import grpc
import requests
from concurrent import futures
import threading
import time

from absl.testing import absltest
from alphagenome import communication_proxy
from alphagenome.protos import dna_model_pb2, dna_model_service_pb2_grpc


class CommunicationProxyTest(absltest.TestCase):
    """Test cases for CommunicationProxyServicer."""

    def setUp(self):
        """Set up test fixtures."""
        self.servicer = communication_proxy.CommunicationProxyServicer()
        self.mock_context = Mock()
        self.mock_context.set_details = Mock()
        self.mock_context.set_code = Mock()

    def test_predict_sequence_streaming_success(self):
        """Test successful PredictSequence streaming."""
        # 创建模拟的请求数据
        request1 = dna_model_pb2.PredictSequenceRequest()
        request1.sequence = "ATCGATCG"
        request1.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS
        request1.model_version = "test_model"
        
        request2 = dna_model_pb2.PredictSequenceRequest()
        request2.sequence = "GCTAGCTA"
        request2.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS
        request2.model_version = "test_model"
        
        request_iterator = iter([request1, request2])
        
        # 模拟HTTP响应
        mock_response1 = Mock()
        mock_response1.json.return_value = {
            "output": {
                "output_type": "OUTPUT_TYPE_ATAC"
            }
        }
        mock_response1.raise_for_status.return_value = None
        
        mock_response2 = Mock()
        mock_response2.json.return_value = {
            "output": {
                "output_type": "OUTPUT_TYPE_ATAC"
            }
        }
        mock_response2.raise_for_status.return_value = None
        
        with patch('requests.post') as mock_post:
            mock_post.side_effect = [mock_response1, mock_response2]
            
            # 执行测试
            responses = list(self.servicer.PredictSequence(request_iterator, self.mock_context))
            
            # 验证结果
            self.assertEqual(len(responses), 2)
            self.assertEqual(responses[0].output.output_type, dna_model_pb2.OUTPUT_TYPE_ATAC)
            self.assertEqual(responses[1].output.output_type, dna_model_pb2.OUTPUT_TYPE_ATAC)
            
            # 验证HTTP请求
            self.assertEqual(mock_post.call_count, 2)
            mock_post.assert_any_call(
                f"{communication_proxy.JSON_SERVICE_BASE_URL}/predict_variant",
                json=unittest.mock.ANY,
                headers=unittest.mock.ANY
            )

    def test_predict_interval_streaming_success(self):
        """Test successful PredictInterval streaming."""
        # 创建模拟的请求数据
        request1 = dna_model_pb2.PredictIntervalRequest()
        request1.interval.chromosome = "chr1"
        request1.interval.start = 1000
        request1.interval.end = 2000
        request1.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS
        
        request2 = dna_model_pb2.PredictIntervalRequest()
        request2.interval.chromosome = "chr2"
        request2.interval.start = 2000
        request2.interval.end = 3000
        request2.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS
        
        request_iterator = iter([request1, request2])
        
        # 模拟HTTP响应
        mock_response1 = Mock()
        mock_response1.json.return_value = {
            "output": {
                "output_type": "OUTPUT_TYPE_ATAC"
            }
        }
        mock_response1.raise_for_status.return_value = None
        
        mock_response2 = Mock()
        mock_response2.json.return_value = {
            "output": {
                "output_type": "OUTPUT_TYPE_ATAC"
            }
        }
        mock_response2.raise_for_status.return_value = None
        
        with patch('requests.post') as mock_post:
            mock_post.side_effect = [mock_response1, mock_response2]
            
            # 执行测试
            responses = list(self.servicer.PredictInterval(request_iterator, self.mock_context))
            
            # 验证结果
            self.assertEqual(len(responses), 2)
            self.assertEqual(responses[0].output.output_type, dna_model_pb2.OUTPUT_TYPE_ATAC)
            self.assertEqual(responses[1].output.output_type, dna_model_pb2.OUTPUT_TYPE_ATAC)
            
            # 验证HTTP请求
            self.assertEqual(mock_post.call_count, 2)
            mock_post.assert_any_call(
                f"{communication_proxy.JSON_SERVICE_BASE_URL}/predict_interval",
                json=unittest.mock.ANY,
                headers=unittest.mock.ANY
            )

    def test_predict_sequence_http_error(self):
        """Test PredictSequence with HTTP error."""
        request = dna_model_pb2.PredictSequenceRequest()
        request.sequence = "ATCGATCG"
        request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS
        request_iterator = iter([request])
        
        with patch('requests.post') as mock_post:
            mock_post.side_effect = requests.RequestException("Connection failed")
            
            # 执行测试
            responses = list(self.servicer.PredictSequence(request_iterator, self.mock_context))
            
            # 验证结果
            self.assertEqual(len(responses), 0)
            self.mock_context.set_code.assert_called_with(grpc.StatusCode.INTERNAL)
            self.mock_context.set_details.assert_called()

    def test_predict_interval_http_error(self):
        """Test PredictInterval with HTTP error."""
        request = dna_model_pb2.PredictIntervalRequest()
        request.interval.chromosome = "chr1"
        request.interval.start = 1000
        request.interval.end = 2000
        request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS
        request_iterator = iter([request])
        
        with patch('requests.post') as mock_post:
            mock_post.side_effect = requests.RequestException("Connection failed")
            
            # 执行测试
            responses = list(self.servicer.PredictInterval(request_iterator, self.mock_context))
            
            # 验证结果
            self.assertEqual(len(responses), 0)
            self.mock_context.set_code.assert_called_with(grpc.StatusCode.INTERNAL)
            self.mock_context.set_details.assert_called()

    def test_predict_variant_success(self):
        """Test successful PredictVariant."""
        request = dna_model_pb2.PredictVariantRequest()
        request.interval.chromosome = "chr1"
        request.interval.start = 999
        request.interval.end = 1001
        request.variant.chromosome = "chr1"
        request.variant.position = 1000
        request.variant.reference_bases = "A"
        request.variant.alternate_bases = "T"
        request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS
        
        mock_response = Mock()
        mock_response.json.return_value = {
            "reference_output": {
                "output_type": "OUTPUT_TYPE_ATAC"
            }
        }
        mock_response.raise_for_status.return_value = None
        mock_response.text = '{"reference_output": {"output_type": "OUTPUT_TYPE_ATAC"}}'
        
        with patch('requests.post') as mock_post:
            mock_post.return_value = mock_response
            
            # 执行测试
            response = self.servicer.PredictVariant(request, self.mock_context)
            
            # 验证结果
            self.assertEqual(response.reference_output.output_type, dna_model_pb2.OUTPUT_TYPE_ATAC)

    def test_score_interval_success(self):
        """Test successful ScoreInterval."""
        request = dna_model_pb2.ScoreIntervalRequest()
        request.interval.chromosome = "chr1"
        request.interval.start = 1000
        request.interval.end = 2000
        request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS
        
        mock_response = Mock()
        mock_response.json.return_value = {
            "output": {
                "interval_data": {}
            }
        }
        mock_response.raise_for_status.return_value = None
        mock_response.text = '{"output": {"interval_data": {}}}'
        
        with patch('requests.post') as mock_post:
            mock_post.return_value = mock_response
            
            # 执行测试
            response = self.servicer.ScoreInterval(request, self.mock_context)
            
            # 验证结果
            self.assertIsNotNone(response.output.interval_data)


class CommunicationProxyIntegrationTest(absltest.TestCase):
    """Integration tests for CommunicationProxyServicer."""

    def setUp(self):
        """Set up test fixtures."""
        self.server = None
        self.channel = None

    def tearDown(self):
        """Clean up test fixtures."""
        if self.channel:
            self.channel.close()
        if self.server:
            self.server.stop(0)

    def start_test_server(self):
        """Start a test gRPC server."""
        self.server = grpc.server(futures.ThreadPoolExecutor(max_workers=1))
        dna_model_service_pb2_grpc.add_DnaModelServiceServicer_to_server(
            communication_proxy.CommunicationProxyServicer(), self.server
        )
        port = self.server.add_insecure_port('[::]:0')
        self.server.start()
        return port

    def test_grpc_server_startup(self):
        """Test that the gRPC server can start successfully."""
        try:
            port = self.start_test_server()
            self.assertIsNotNone(port)
            self.assertGreater(port, 0)
        except Exception as e:
            self.fail(f"Failed to start gRPC server: {e}")

    def test_grpc_client_connection(self):
        """Test gRPC client can connect to the server."""
        port = self.start_test_server()
        self.channel = grpc.insecure_channel(f'localhost:{port}')
        stub = dna_model_service_pb2_grpc.DnaModelServiceStub(self.channel)
        
        # 测试连接是否建立
        self.assertIsNotNone(stub)


if __name__ == '__main__':
    absltest.main() 