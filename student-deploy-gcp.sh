#!/bin/bash

# 🎓 学生 Google Cloud 一键部署脚本
# AlphaGenome 通信代理

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

echo "🎓 AlphaGenome 学生免费云部署脚本"
echo "=================================="

# 检查依赖
log_info "检查部署依赖..."

# 检查 Docker
if ! command -v docker &> /dev/null; then
    log_error "❌ 请先安装 Docker"
    echo "安装命令："
    echo "  macOS: brew install docker"
    echo "  Linux: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

# 检查 Google Cloud SDK
if ! command -v gcloud &> /dev/null; then
    log_error "❌ 请先安装 Google Cloud SDK"
    echo "安装命令："
    echo "  macOS: brew install google-cloud-sdk"
    echo "  Linux: curl https://sdk.cloud.google.com | bash"
    echo "  然后运行: gcloud init"
    exit 1
fi

# 检查是否已登录
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    log_error "❌ 请先登录 Google Cloud"
    echo "运行命令：gcloud auth login"
    exit 1
fi

log_success "✅ 所有依赖已满足"

# 设置变量
export PROJECT_ID=alphagenome-student-$(date +%s)
export ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw
export REGION=us-central1

log_info "📦 创建项目: $PROJECT_ID"

# 创建项目
if gcloud projects create $PROJECT_ID --quiet; then
    log_success "✅ 项目创建成功"
else
    log_error "❌ 项目创建失败，可能项目名已存在"
    export PROJECT_ID=alphagenome-student-$(date +%s)-$(openssl rand -hex 4)
    log_info "🔄 尝试使用新项目名: $PROJECT_ID"
    gcloud projects create $PROJECT_ID --quiet
fi

# 设置项目
gcloud config set project $PROJECT_ID
log_success "✅ 项目设置完成"

# 启用必要服务
log_info "🔧 启用 Google Cloud 服务..."
gcloud services enable run.googleapis.com --quiet
gcloud services enable containerregistry.googleapis.com --quiet
log_success "✅ 服务启用完成"

# 配置 Docker 认证
log_info "🔐 配置 Docker 认证..."
gcloud auth configure-docker --quiet
log_success "✅ Docker 认证配置完成"

# 构建 Docker 镜像
log_info "🐳 构建 Docker 镜像..."
if docker build -t gcr.io/$PROJECT_ID/alphagenome-proxy .; then
    log_success "✅ Docker 镜像构建成功"
else
    log_error "❌ Docker 镜像构建失败"
    exit 1
fi

# 推送镜像到 Google Container Registry
log_info "📤 推送镜像到 Google Container Registry..."
if docker push gcr.io/$PROJECT_ID/alphagenome-proxy; then
    log_success "✅ 镜像推送成功"
else
    log_error "❌ 镜像推送失败"
    exit 1
fi

# 部署到 Cloud Run
log_info "🚀 部署到 Google Cloud Run..."
if gcloud run deploy alphagenome-proxy \
  --image gcr.io/$PROJECT_ID/alphagenome-proxy \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --set-env-vars ALPHAGENOME_API_KEY=$ALPHAGENOME_API_KEY \
  --set-env-vars JSON_SERVICE_BASE_URL=https://api.alphagenome.google.com \
  --set-env-vars API_KEY_HEADER=Authorization \
  --set-env-vars API_KEY_PREFIX="Bearer " \
  --port 50051 \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 5 \
  --quiet; then
    log_success "✅ 部署成功"
else
    log_error "❌ 部署失败"
    exit 1
fi

# 获取服务 URL
log_info "🌐 获取服务地址..."
SERVICE_URL=$(gcloud run services describe alphagenome-proxy \
  --region $REGION \
  --format 'value(status.url)' \
  --quiet)

if [ -n "$SERVICE_URL" ]; then
    log_success "✅ 服务部署完成！"
    echo ""
    echo "🎉 部署成功！"
    echo "=================================="
    echo "🌐 服务地址: $SERVICE_URL"
    echo "🔗 gRPC 端点: $SERVICE_URL:50051"
    echo "📊 项目 ID: $PROJECT_ID"
    echo "🌍 区域: $REGION"
    echo ""
    echo "🧪 测试服务:"
    echo "curl -X GET $SERVICE_URL/health"
    echo ""
    echo "📚 查看日志:"
    echo "gcloud logs tail --project=$PROJECT_ID --service=alphagenome-proxy"
    echo ""
    echo "💰 成本信息:"
    echo "- 免费额度: 每月 200万请求"
    echo "- 超出费用: $0.0000024/请求"
    echo "- 学生优惠: $300 免费额度"
    echo ""
    echo "🎓 学习资源:"
    echo "- Google Cloud 学习: https://cloud.google.com/learn"
    echo "- 学生优惠: https://cloud.google.com/edu"
    echo ""
else
    log_error "❌ 无法获取服务地址"
    exit 1
fi

# 保存配置信息
cat > deployment-info.txt << EOF
AlphaGenome 通信代理部署信息
============================
部署时间: $(date)
项目 ID: $PROJECT_ID
服务地址: $SERVICE_URL
gRPC 端点: $SERVICE_URL:50051
区域: $REGION
API Key: $ALPHAGENOME_API_KEY

测试命令:
curl -X GET $SERVICE_URL/health

查看日志:
gcloud logs tail --project=$PROJECT_ID --service=alphagenome-proxy

删除服务:
gcloud run services delete alphagenome-proxy --region=$REGION --quiet
gcloud projects delete $PROJECT_ID --quiet
EOF

log_success "📄 部署信息已保存到 deployment-info.txt"

echo ""
echo "🎓 恭喜！你的 AlphaGenome 通信代理已成功部署到 Google Cloud！"
echo "💡 提示：记得定期检查使用量，避免超出免费额度" 