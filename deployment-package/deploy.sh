#!/bin/bash

# 🚀 AlphaGenome 代理服务一键部署脚本

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
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

# 检查必需的环境变量
check_env_vars() {
    print_info "检查环境变量..."
    
    if [ -z "$PROJECT_ID" ]; then
        print_error "PROJECT_ID 环境变量未设置"
        echo "请设置: export PROJECT_ID=your_project_id"
        exit 1
    fi
    
    if [ -z "$ALPHAGENOME_API_KEY" ]; then
        print_error "ALPHAGENOME_API_KEY 环境变量未设置"
        echo "请设置: export ALPHAGENOME_API_KEY=your_api_key"
        exit 1
    fi
    
    print_success "环境变量检查通过"
}

# 检查 Google Cloud CLI
check_gcloud() {
    print_info "检查 Google Cloud CLI..."
    
    if ! command -v gcloud &> /dev/null; then
        print_error "Google Cloud CLI 未安装"
        echo "请安装: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "Google Cloud 未认证"
        echo "请运行: gcloud auth login"
        exit 1
    fi
    
    print_success "Google Cloud CLI 检查通过"
}

# 设置项目
setup_project() {
    print_info "设置 Google Cloud 项目..."
    
    gcloud config set project $PROJECT_ID
    
    # 检查项目是否存在
    if ! gcloud projects describe $PROJECT_ID &> /dev/null; then
        print_error "项目 $PROJECT_ID 不存在"
        echo "请创建项目或检查项目 ID"
        exit 1
    fi
    
    print_success "项目设置完成: $PROJECT_ID"
}

# 启用必要的 API
enable_apis() {
    print_info "启用必要的 Google Cloud API..."
    
    gcloud services enable \
        cloudbuild.googleapis.com \
        run.googleapis.com \
        storage.googleapis.com \
        containerregistry.googleapis.com \
        logging.googleapis.com
    
    print_success "API 启用完成"
}

# 创建服务账号
create_service_account() {
    print_info "创建服务账号..."
    
    # 检查服务账号是否已存在
    if gcloud iam service-accounts describe alphagenome-proxy@$PROJECT_ID.iam.gserviceaccount.com &> /dev/null; then
        print_warning "服务账号已存在，跳过创建"
        return
    fi
    
    gcloud iam service-accounts create alphagenome-proxy \
        --display-name="AlphaGenome Proxy Service Account"
    
    # 分配权限
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:alphagenome-proxy@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="roles/run.admin"
    
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:alphagenome-proxy@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="roles/storage.admin"
    
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:alphagenome-proxy@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="roles/iam.serviceAccountUser"
    
    print_success "服务账号创建完成"
}

# 构建 Docker 镜像
build_image() {
    print_info "构建 Docker 镜像..."
    
    SERVICE_NAME="alphagenome-proxy"
    REGION="us-central1"
    
    # 构建并推送镜像
    gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME
    
    print_success "Docker 镜像构建完成"
}

# 部署到 Cloud Run
deploy_service() {
    print_info "部署到 Cloud Run..."
    
    SERVICE_NAME="alphagenome-proxy"
    REGION="us-central1"
    MEMORY="512Mi"
    CPU="1"
    MAX_INSTANCES="10"
    
    # 部署服务
    gcloud run deploy $SERVICE_NAME \
        --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
        --platform managed \
        --region $REGION \
        --allow-unauthenticated \
        --memory $MEMORY \
        --cpu $CPU \
        --max-instances $MAX_INSTANCES \
        --set-env-vars ALPHAGENOME_API_KEY=$ALPHAGENOME_API_KEY \
        --service-account=alphagenome-proxy@$PROJECT_ID.iam.gserviceaccount.com
    
    print_success "服务部署完成"
}

# 获取服务 URL
get_service_url() {
    print_info "获取服务 URL..."
    
    SERVICE_NAME="alphagenome-proxy"
    REGION="us-central1"
    
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")
    
    print_success "服务 URL: $SERVICE_URL"
    echo ""
    echo "🌐 你的服务已部署在:"
    echo "   $SERVICE_URL"
    echo ""
    echo "🔗 gRPC 端点:"
    echo "   ${SERVICE_URL#https://}:443"
    echo ""
}

# 测试服务
test_service() {
    print_info "测试服务..."
    
    SERVICE_NAME="alphagenome-proxy"
    REGION="us-central1"
    
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")
    
    # 简单的健康检查
    if curl -s "$SERVICE_URL/health" | grep -q "OK"; then
        print_success "服务健康检查通过"
    else
        print_warning "服务健康检查失败，但部署可能仍然成功"
    fi
}

# 显示部署信息
show_deployment_info() {
    echo ""
    echo "🎉 部署完成！"
    echo "=================="
    echo ""
    echo "📊 部署信息:"
    echo "   项目 ID: $PROJECT_ID"
    echo "   服务名称: alphagenome-proxy"
    echo "   区域: us-central1"
    echo "   内存: 512Mi"
    echo "   CPU: 1"
    echo "   最大实例: 10"
    echo ""
    echo "🔧 管理命令:"
    echo "   查看日志: gcloud logging read 'resource.type=cloud_run_revision'"
    echo "   查看状态: gcloud run services describe alphagenome-proxy --region=us-central1"
    echo "   更新服务: gcloud run services update alphagenome-proxy --region=us-central1"
    echo "   删除服务: gcloud run services delete alphagenome-proxy --region=us-central1"
    echo ""
    echo "💰 成本估算:"
    echo "   免费额度: 每月 200万请求"
    echo "   典型使用: 几乎免费"
    echo ""
}

# 主函数
main() {
    echo "🚀 AlphaGenome 代理服务部署脚本"
    echo "=================================="
    echo ""
    
    # 检查环境
    check_env_vars
    check_gcloud
    
    # 部署流程
    setup_project
    enable_apis
    create_service_account
    build_image
    deploy_service
    get_service_url
    test_service
    show_deployment_info
    
    print_success "部署完成！"
}

# 运行主函数
main "$@" 