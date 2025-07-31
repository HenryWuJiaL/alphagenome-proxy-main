#!/bin/bash

# 🧪 AlphaGenome 代理服务测试脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 获取服务 URL
get_service_url() {
    SERVICE_NAME="alphagenome-proxy"
    REGION="us-central1"
    
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")
    echo $SERVICE_URL
}

# 测试 HTTP 健康检查
test_http_health() {
    print_info "测试 HTTP 健康检查..."
    
    SERVICE_URL=$(get_service_url)
    
    if curl -s "$SERVICE_URL/health" | grep -q "OK"; then
        print_success "HTTP 健康检查通过"
        return 0
    else
        print_error "HTTP 健康检查失败"
        return 1
    fi
}

# 测试 gRPC 连接
test_grpc_connection() {
    print_info "测试 gRPC 连接..."
    
    SERVICE_URL=$(get_service_url)
    GRPC_ENDPOINT="${SERVICE_URL#https://}:443"
    
    # 创建简单的 gRPC 测试脚本
    cat > /tmp/test_grpc.py << 'EOF'
import grpc
import sys
sys.path.append('src')

from alphagenome.protos import dna_model_service_pb2_grpc, dna_model_pb2

def test_grpc():
    try:
        # 连接到服务
        credentials = grpc.ssl_channel_credentials()
        channel = grpc.secure_channel("alphagenome-proxy-175461151316.us-central1.run.app:443", credentials)
        stub = dna_model_service_pb2_grpc.DnaModelServiceStub(channel)
        
        # 创建简单的请求
        request = dna_model_service_pb2.PredictVariantRequest()
        request.interval.chromosome = "chr22"
        request.interval.start = 35677410
        request.interval.end = 36725986
        request.variant.chromosome = "chr22"
        request.variant.position = 36201698
        request.variant.reference_bases = "A"
        request.variant.alternate_bases = "C"
        request.organism = dna_model_pb2.ORGANISM_HOMO_SAPIENS
        
        # 发送请求
        response = stub.PredictVariant(request, timeout=30)
        print("gRPC 测试成功")
        return True
    except Exception as e:
        print(f"gRPC 测试失败: {e}")
        return False

if __name__ == "__main__":
    test_grpc()
EOF
    
    if python /tmp/test_grpc.py; then
        print_success "gRPC 连接测试通过"
        rm /tmp/test_grpc.py
        return 0
    else
        print_error "gRPC 连接测试失败"
        rm /tmp/test_grpc.py
        return 1
    fi
}

# 测试服务日志
test_service_logs() {
    print_info "检查服务日志..."
    
    SERVICE_NAME="alphagenome-proxy"
    REGION="us-central1"
    
    # 获取最近的日志
    LOGS=$(gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME" --limit=10 --format="value(timestamp,severity,textPayload)")
    
    if [ -n "$LOGS" ]; then
        print_success "服务日志正常"
        echo "最近的日志:"
        echo "$LOGS" | head -5
    else
        print_warning "没有找到服务日志"
    fi
}

# 测试服务状态
test_service_status() {
    print_info "检查服务状态..."
    
    SERVICE_NAME="alphagenome-proxy"
    REGION="us-central1"
    
    STATUS=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.conditions[0].status)")
    
    if [ "$STATUS" = "True" ]; then
        print_success "服务状态正常"
    else
        print_error "服务状态异常"
        return 1
    fi
}

# 性能测试
test_performance() {
    print_info "性能测试..."
    
    SERVICE_URL=$(get_service_url)
    
    # 测试响应时间
    START_TIME=$(date +%s.%N)
    curl -s "$SERVICE_URL/health" > /dev/null
    END_TIME=$(date +%s.%N)
    
    RESPONSE_TIME=$(echo "$END_TIME - $START_TIME" | bc)
    
    if (( $(echo "$RESPONSE_TIME < 1.0" | bc -l) )); then
        print_success "响应时间正常: ${RESPONSE_TIME}s"
    else
        print_warning "响应时间较慢: ${RESPONSE_TIME}s"
    fi
}

# 显示服务信息
show_service_info() {
    print_info "服务信息..."
    
    SERVICE_NAME="alphagenome-proxy"
    REGION="us-central1"
    SERVICE_URL=$(get_service_url)
    
    echo ""
    echo "📊 服务信息:"
    echo "   服务名称: $SERVICE_NAME"
    echo "   区域: $REGION"
    echo "   HTTP URL: $SERVICE_URL"
    echo "   gRPC 端点: ${SERVICE_URL#https://}:443"
    echo ""
    
    # 显示服务配置
    gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(spec.template.spec.containers[0].resources.limits.memory,spec.template.spec.containers[0].resources.limits.cpu)" | while read MEMORY CPU; do
        echo "   内存限制: $MEMORY"
        echo "   CPU 限制: $CPU"
    done
}

# 主函数
main() {
    echo "🧪 AlphaGenome 代理服务测试"
    echo "============================="
    echo ""
    
    # 检查 gcloud 是否可用
    if ! command -v gcloud &> /dev/null; then
        print_error "Google Cloud CLI 未安装"
        exit 1
    fi
    
    # 运行测试
    TESTS_PASSED=0
    TESTS_TOTAL=0
    
    # 测试服务状态
    if test_service_status; then
        ((TESTS_PASSED++))
    fi
    ((TESTS_TOTAL++))
    
    # 测试 HTTP 健康检查
    if test_http_health; then
        ((TESTS_PASSED++))
    fi
    ((TESTS_TOTAL++))
    
    # 测试 gRPC 连接
    if test_grpc_connection; then
        ((TESTS_PASSED++))
    fi
    ((TESTS_TOTAL++))
    
    # 性能测试
    test_performance
    ((TESTS_TOTAL++))
    
    # 检查日志
    test_service_logs
    
    # 显示服务信息
    show_service_info
    
    # 测试结果总结
    echo ""
    echo "📊 测试结果:"
    echo "   通过: $TESTS_PASSED/$TESTS_TOTAL"
    
    if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
        print_success "所有测试通过！"
        exit 0
    else
        print_warning "部分测试失败"
        exit 1
    fi
}

# 运行主函数
main "$@" 