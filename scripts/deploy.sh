#!/bin/bash

# AlphaGenome Communication Proxy 部署脚本
# 支持多种平台：Docker、AWS、GCP、Kubernetes

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查部署依赖..."
    
    local missing_deps=()
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    # 检查 Python
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少以下依赖: ${missing_deps[*]}"
        exit 1
    fi
    
    log_success "所有依赖已满足"
}

# 构建 Docker 镜像
build_docker_image() {
    local tag=${1:-"alphagenome-proxy:latest"}
    
    log_info "构建 Docker 镜像: $tag"
    
    if docker build -t "$tag" .; then
        log_success "Docker 镜像构建成功"
    else
        log_error "Docker 镜像构建失败"
        exit 1
    fi
}

# 本地 Docker 部署
deploy_local_docker() {
    log_info "开始本地 Docker 部署..."
    
    # 停止现有容器
    docker-compose down 2>/dev/null || true
    
    # 启动服务
    if docker-compose up -d; then
        log_success "本地 Docker 部署成功"
        log_info "服务地址: localhost:50051"
        log_info "查看日志: docker-compose logs -f"
    else
        log_error "本地 Docker 部署失败"
        exit 1
    fi
}

# AWS 部署
deploy_aws() {
    local environment=${1:-"production"}
    local region=${2:-"us-east-1"}
    
    log_info "开始 AWS 部署 (环境: $environment, 区域: $region)..."
    
    # 检查 AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "请先安装 AWS CLI"
        exit 1
    fi
    
    # 检查 API Key
    if [ -z "$ALPHAGENOME_API_KEY" ]; then
        log_error "请设置 ALPHAGENOME_API_KEY 环境变量"
        exit 1
    fi
    
    # 构建并推送镜像到 ECR
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local ecr_repo="$account_id.dkr.ecr.$region.amazonaws.com/alphagenome-proxy"
    
    log_info "推送镜像到 ECR: $ecr_repo"
    
    # 创建 ECR 仓库（如果不存在）
    aws ecr describe-repositories --repository-names alphagenome-proxy --region "$region" 2>/dev/null || \
    aws ecr create-repository --repository-name alphagenome-proxy --region "$region"
    
    # 登录 ECR
    aws ecr get-login-password --region "$region" | docker login --username AWS --password-stdin "$account_id.dkr.ecr.$region.amazonaws.com"
    
    # 构建和推送镜像
    build_docker_image "$ecr_repo:latest"
    docker push "$ecr_repo:latest"
    
    # 部署 CloudFormation 栈
    log_info "部署 CloudFormation 栈..."
    
    aws cloudformation deploy \
        --template-file deploy/aws/cloudformation.yaml \
        --stack-name "alphagenome-proxy-$environment" \
        --parameter-overrides \
            ApiKey="$ALPHAGENOME_API_KEY" \
            Environment="$environment" \
        --capabilities CAPABILITY_IAM \
        --region "$region"
    
    # 获取输出
    local alb_dns=$(aws cloudformation describe-stacks \
        --stack-name "alphagenome-proxy-$environment" \
        --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
        --output text \
        --region "$region")
    
    log_success "AWS 部署成功"
    log_info "负载均衡器地址: $alb_dns"
}

# GCP 部署
deploy_gcp() {
    local project_id=${1:-$(gcloud config get-value project)}
    local region=${2:-"us-central1"}
    
    log_info "开始 GCP 部署 (项目: $project_id, 区域: $region)..."
    
    # 检查 gcloud CLI
    if ! command -v gcloud &> /dev/null; then
        log_error "请先安装 Google Cloud SDK"
        exit 1
    fi
    
    # 检查 API Key
    if [ -z "$ALPHAGENOME_API_KEY" ]; then
        log_error "请设置 ALPHAGENOME_API_KEY 环境变量"
        exit 1
    fi
    
    # 构建并推送镜像到 GCR
    local gcr_repo="gcr.io/$project_id/alphagenome-proxy"
    
    log_info "推送镜像到 GCR: $gcr_repo"
    
    build_docker_image "$gcr_repo:latest"
    docker push "$gcr_repo:latest"
    
    # 创建 Secret
    log_info "创建 Kubernetes Secret..."
    
    kubectl create secret generic alphagenome-api-key \
        --from-literal=api-key="$ALPHAGENOME_API_KEY" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # 部署到 Cloud Run
    log_info "部署到 Cloud Run..."
    
    gcloud run deploy alphagenome-proxy \
        --image "$gcr_repo:latest" \
        --platform managed \
        --region "$region" \
        --allow-unauthenticated \
        --port 50051 \
        --memory 512Mi \
        --cpu 1 \
        --set-env-vars "JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com,API_KEY_HEADER=Authorization,API_KEY_PREFIX=Bearer " \
        --set-secrets "ALPHAGENOME_API_KEY=alphagenome-api-key:api-key"
    
    # 获取服务 URL
    local service_url=$(gcloud run services describe alphagenome-proxy \
        --platform managed \
        --region "$region" \
        --format "value(status.url)")
    
    log_success "GCP 部署成功"
    log_info "服务地址: $service_url"
}

# Kubernetes 部署
deploy_kubernetes() {
    local namespace=${1:-"default"}
    
    log_info "开始 Kubernetes 部署 (命名空间: $namespace)..."
    
    # 检查 kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "请先安装 kubectl"
        exit 1
    fi
    
    # 检查 API Key
    if [ -z "$ALPHAGENOME_API_KEY" ]; then
        log_error "请设置 ALPHAGENOME_API_KEY 环境变量"
        exit 1
    fi
    
    # 创建命名空间（如果不存在）
    kubectl create namespace "$namespace" 2>/dev/null || true
    
    # 创建 Secret
    log_info "创建 Kubernetes Secret..."
    
    kubectl create secret generic alphagenome-api-key \
        --from-literal=api-key="$ALPHAGENOME_API_KEY" \
        --namespace "$namespace" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # 部署应用
    log_info "部署应用到 Kubernetes..."
    
    kubectl apply -f deploy/kubernetes/deployment.yaml -n "$namespace"
    
    # 等待部署完成
    kubectl rollout status deployment/alphagenome-proxy -n "$namespace"
    
    log_success "Kubernetes 部署成功"
    log_info "查看服务状态: kubectl get pods -n $namespace"
    log_info "查看服务: kubectl get svc -n $namespace"
}

# 显示帮助信息
show_help() {
    echo "AlphaGenome Communication Proxy 部署脚本"
    echo ""
    echo "用法: $0 [选项] [平台]"
    echo ""
    echo "平台选项:"
    echo "  local-docker    本地 Docker 部署"
    echo "  aws [env] [region]    AWS 部署 (环境: dev/staging/prod, 区域: us-east-1)"
    echo "  gcp [project] [region] GCP 部署 (项目ID, 区域: us-central1)"
    echo "  k8s [namespace]      Kubernetes 部署 (命名空间: default)"
    echo ""
    echo "选项:"
    echo "  -h, --help      显示此帮助信息"
    echo "  -b, --build     仅构建 Docker 镜像"
    echo ""
    echo "环境变量:"
    echo "  ALPHAGENOME_API_KEY    AlphaGenome API Key (必需)"
    echo "  JSON_SERVICE_BASE_URL  JSON 服务地址 (可选)"
    echo ""
    echo "示例:"
    echo "  $0 local-docker"
    echo "  $0 aws production us-east-1"
    echo "  $0 gcp my-project us-central1"
    echo "  $0 k8s alphagenome"
}

# 主函数
main() {
    local platform=""
    local build_only=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -b|--build)
                build_only=true
                shift
                ;;
            local-docker|aws|gcp|k8s)
                platform="$1"
                shift
                break
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 检查依赖
    check_dependencies
    
    # 仅构建模式
    if [ "$build_only" = true ]; then
        build_docker_image
        exit 0
    fi
    
    # 根据平台部署
    case $platform in
        local-docker)
            deploy_local_docker
            ;;
        aws)
            deploy_aws "$1" "$2"
            ;;
        gcp)
            deploy_gcp "$1" "$2"
            ;;
        k8s)
            deploy_kubernetes "$1"
            ;;
        "")
            log_error "请指定部署平台"
            show_help
            exit 1
            ;;
        *)
            log_error "不支持的平台: $platform"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@" 