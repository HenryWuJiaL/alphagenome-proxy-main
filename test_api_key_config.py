#!/usr/bin/env python3
"""
测试 API key 配置的脚本
"""

import os
import sys
import requests
from unittest.mock import Mock, patch

# 添加 src 目录到 Python 路径
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

def test_api_key_config():
    """测试 API key 配置"""
    print("=== API Key 配置测试 ===")
    
    # 检查环境变量
    api_key = os.getenv("ALPHAGENOME_API_KEY", "")
    json_service_url = os.getenv("JSON_SERVICE_BASE_URL", "http://127.0.0.1:8000")
    api_key_header = os.getenv("API_KEY_HEADER", "Authorization")
    api_key_prefix = os.getenv("API_KEY_PREFIX", "Bearer ")
    
    print(f"JSON 服务地址: {json_service_url}")
    print(f"API Key 已配置: {'是' if api_key else '否'}")
    if api_key:
        print(f"API Key Header: {api_key_header}")
        print(f"API Key 前缀: '{api_key_prefix}'")
        print(f"API Key (前4位): {api_key[:4]}...")
    else:
        print("警告: 未配置 API Key")
    
    # 测试请求头构建
    print("\n=== 测试请求头构建 ===")
    
    def _get_headers():
        """构建包含API key的请求头"""
        headers = {
            'Content-Type': 'application/json',
        }
        
        if api_key:
            if api_key_header == "Authorization":
                headers[api_key_header] = f"{api_key_prefix}{api_key}"
            else:
                headers[api_key_header] = api_key
        
        return headers
    
    headers = _get_headers()
    print("构建的请求头:")
    for key, value in headers.items():
        if key.lower() in ['authorization', 'x-api-key']:
            # 隐藏敏感信息
            if value:
                print(f"  {key}: {value[:10]}...")
            else:
                print(f"  {key}: (未设置)")
        else:
            print(f"  {key}: {value}")
    
    # 测试 HTTP 请求
    print("\n=== 测试 HTTP 请求 ===")
    
    test_data = {"test": "data"}
    
    try:
        # 使用 mock 来避免实际发送请求
        with patch('requests.post') as mock_post:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = {"status": "success"}
            mock_response.raise_for_status.return_value = None
            mock_post.return_value = mock_response
            
            response = requests.post(
                f"{json_service_url}/test",
                json=test_data,
                headers=headers,
                timeout=5
            )
            
            print(f"请求状态码: {response.status_code}")
            print(f"响应内容: {response.json()}")
            
            # 验证请求头是否正确发送
            mock_post.assert_called_once()
            call_args = mock_post.call_args
            actual_headers = call_args[1]['headers']
            
            print("\n实际发送的请求头:")
            for key, value in actual_headers.items():
                if key.lower() in ['authorization', 'x-api-key']:
                    if value:
                        print(f"  {key}: {value[:10]}...")
                    else:
                        print(f"  {key}: (未设置)")
                else:
                    print(f"  {key}: {value}")
                    
    except Exception as e:
        print(f"测试失败: {e}")
    
    print("\n=== 测试完成 ===")

def test_with_real_api_key():
    """使用真实 API key 进行测试（可选）"""
    api_key = os.getenv("ALPHAGENOME_API_KEY", "")
    if not api_key:
        print("未配置 API key，跳过真实 API 测试")
        return
    
    print("\n=== 真实 API 测试 ===")
    print("注意: 这将发送真实的 HTTP 请求到配置的服务")
    
    # 这里可以添加真实的 API 调用测试
    # 例如测试 AlphaGenome 的某个简单端点
    
    print("真实 API 测试功能待实现")

if __name__ == "__main__":
    test_api_key_config()
    test_with_real_api_key() 