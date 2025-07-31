#!/usr/bin/env python3
"""
简化的 Mock JSON 服务，用于测试 communication_proxy
"""

import base64
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/predict_variant', methods=['POST'])
def predict_variant():
    data = request.json
    print(f"收到 predict_variant 请求: {data}")
    return jsonify({
        "output": {
            "output_type": "OUTPUT_TYPE_RNA_SEQ",
            "data": {
                "shape": [1],
                "data_type": "DATA_TYPE_FLOAT32",
                "array": {
                    "data": base64.b64encode(b"\x00\x00\xd8\x3f").decode('utf-8')  # 0.85 in float32 bytes
                }
            }
        }
    })

@app.route('/predict_interval', methods=['POST'])
def predict_interval():
    data = request.json
    print(f"收到 predict_interval 请求: {data}")
    return jsonify({
        "output": {
            "output_type": "OUTPUT_TYPE_RNA_SEQ",
            "track_data": {
                "values": {
                    "shape": [1],
                    "data_type": "DATA_TYPE_FLOAT32",
                    "array": {
                        "data": base64.b64encode(b"\x00\x00\x40\x3f").decode('utf-8')  # 0.75 in float32 bytes
                    }
                },
                "interval": {
                    "chromosome": data.get('interval', {}).get('chromosome', 'chr1'),
                    "start": data.get('interval', {}).get('start', 0),
                    "end": data.get('interval', {}).get('end', 1000)
                }
            }
        }
    })

@app.route('/score_interval', methods=['POST'])
def score_interval():
    data = request.json
    print(f"收到 score_interval 请求: {data}")
    return jsonify({
        "interval_data": {
            "metadata": {
                "chromosome": data.get('interval', {}).get('chromosome', 'chr1'),
                "start": data.get('interval', {}).get('start', 0),
                "end": data.get('interval', {}).get('end', 1000)
            },
            "data": {
                "shape": [1],
                "data_type": "DATA_TYPE_FLOAT32",
                                    "array": {
                        "data": base64.b64encode(b"\x00\x00\x5e\x3f").decode('utf-8')  # 0.87 in float32 bytes
                    }
            }
        }
    })

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    print("启动简化的 Mock JSON 服务...")
    app.run(host='0.0.0.0', port=8000, debug=False) 