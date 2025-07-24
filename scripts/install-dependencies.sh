#!/bin/bash

# AlphaGenome Communication Proxy 依赖安装脚本
# 支持 Linux、macOS、Windows (WSL)

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

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Linux*)     
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                OS="$NAME"
                VER="$VERSION_ID"
            else
                OS="Linux"
            fi
            ;;
        Darwin*)    OS="macOS";;
        CYGWIN*)    OS="Windows";;
        MINGW*)     OS="Windows";;
        *)          OS="Unknown";;
    esac
    
    log_info "检测到操作系统: $OS"
}

# 安装 Python
install_python() {
    log_info "安装 Python 3.11..."
    
    case "$OS" in
        "Ubuntu"|"Debian GNU/Linux")
            sudo apt-get update
            sudo apt-get install -y python3.11 python3.11-pip python3.11-venv
            ;;
        "CentOS Linux"|"Red Hat Enterprise Linux")
            sudo yum install -y python3.11 python3.11-pip
            ;;
        "macOS")
            if ! command -v brew &> /dev/null; then
                log_info "安装 Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install python@3.11
            ;;
        "Windows")
            log_warning "Windows 用户请手动安装 Python 3.11: https://www.python.org/downloads/"
            return 1
            ;;
        *)
            log_error "不支持的操作系统: $OS"
            return 1
            ;;
    esac
    
    log_success "Python 安装完成"
}

# 安装 Docker
install_docker() {
    log_info "安装 Docker..."
    
    case "$OS" in
        "Ubuntu"|"Debian GNU/Linux")
            # 卸载旧版本
            sudo apt-get remove -y docker docker-engine docker.io containerd runc
            
            # 安装依赖
            sudo apt-get update
            sudo apt-get install -y \
                apt-transport-https \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            # 添加 Docker 官方 GPG 密钥
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # 设置稳定版仓库
            echo \
                "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # 安装 Docker Engine
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            
            # 启动 Docker
            sudo systemctl start docker
            sudo systemctl enable docker
            
            # 添加用户到 docker 组
            sudo usermod -aG docker $USER
            ;;
            
        "CentOS Linux"|"Red Hat Enterprise Linux")
            # 卸载旧版本
            sudo yum remove -y docker \
                docker-client \
                docker-client-latest \
                docker-common \
                docker-latest \
                docker-latest-logrotate \
                docker-logrotate \
                docker-engine
            
            # 安装依赖
            sudo yum install -y yum-utils
            
            # 设置仓库
            sudo yum-config-manager \
                --add-repo \
                https://download.docker.com/linux/centos/docker-ce.repo
            
            # 安装 Docker Engine
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            
            # 启动 Docker
            sudo systemctl start docker
            sudo systemctl enable docker
            
            # 添加用户到 docker 组
            sudo usermod -aG docker $USER
            ;;
            
        "macOS")
            if ! command -v brew &> /dev/null; then
                log_error "请先安装 Homebrew"
                return 1
            fi
            
            # 安装 Docker Desktop
            brew install --cask docker
            ;;
            
        "Windows")
            log_warning "Windows 用户请手动安装 Docker Desktop: https://www.docker.com/products/docker-desktop"
            return 1
            ;;
            
        *)
            log_error "不支持的操作系统: $OS"
            return 1
            ;;
    esac
    
    log_success "Docker 安装完成"
}

# 安装 Docker Compose
install_docker_compose() {
    log_info "安装 Docker Compose..."
    
    # 检查是否已安装
    if command -v docker-compose &> /dev/null; then
        log_info "Docker Compose 已安装"
        return 0
    fi
    
    # 下载最新版本
    local version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    
    sudo curl -L "https://github.com/docker/compose/releases/download/$version/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    log_success "Docker Compose 安装完成"
}

# 安装 AWS CLI
install_aws_cli() {
    log_info "安装 AWS CLI..."
    
    case "$OS" in
        "Ubuntu"|"Debian GNU/Linux"|"CentOS Linux"|"Red Hat Enterprise Linux")
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
            rm -rf aws awscliv2.zip
            ;;
        "macOS")
            curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
            sudo installer -pkg AWSCLIV2.pkg -target /
            rm AWSCLIV2.pkg
            ;;
        "Windows")
            log_warning "Windows 用户请手动安装 AWS CLI: https://aws.amazon.com/cli/"
            return 1
            ;;
    esac
    
    log_success "AWS CLI 安装完成"
}

# 安装 Google Cloud SDK
install_gcloud() {
    log_info "安装 Google Cloud SDK..."
    
    case "$OS" in
        "Ubuntu"|"Debian GNU/Linux"|"CentOS Linux"|"Red Hat Enterprise Linux")
            # 添加 Google Cloud 仓库
            echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
            curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
            
            # 安装 SDK
            sudo apt-get update && sudo apt-get install -y google-cloud-sdk
            ;;
        "macOS")
            curl https://sdk.cloud.google.com | bash
            exec -l $SHELL
            ;;
        "Windows")
            log_warning "Windows 用户请手动安装 Google Cloud SDK: https://cloud.google.com/sdk/docs/install"
            return 1
            ;;
    esac
    
    log_success "Google Cloud SDK 安装完成"
}

# 安装 kubectl
install_kubectl() {
    log_info "安装 kubectl..."
    
    case "$OS" in
        "Ubuntu"|"Debian GNU/Linux"|"CentOS Linux"|"Red Hat Enterprise Linux")
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
            ;;
        "macOS")
            brew install kubectl
            ;;
        "Windows")
            log_warning "Windows 用户请手动安装 kubectl: https://kubernetes.io/docs/tasks/tools/"
            return 1
            ;;
    esac
    
    log_success "kubectl 安装完成"
}

# 创建虚拟环境
create_venv() {
    log_info "创建 Python 虚拟环境..."
    
    if [ ! -d "venv" ]; then
        python3.11 -m venv venv
        log_success "虚拟环境创建完成"
    else
        log_info "虚拟环境已存在"
    fi
    
    # 激活虚拟环境并安装依赖
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    
    log_success "Python 依赖安装完成"
}

# 显示帮助信息
show_help() {
    echo "AlphaGenome Communication Proxy 依赖安装脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示此帮助信息"
    echo "  --python-only       仅安装 Python"
    echo "  --docker-only       仅安装 Docker"
    echo "  --aws-only          仅安装 AWS CLI"
    echo "  --gcp-only          仅安装 Google Cloud SDK"
    echo "  --k8s-only          仅安装 kubectl"
    echo "  --all               安装所有依赖 (默认)"
    echo ""
    echo "支持的操作系统:"
    echo "  - Ubuntu/Debian"
    echo "  - CentOS/RHEL"
    echo "  - macOS"
    echo "  - Windows (WSL)"
}

# 主函数
main() {
    local install_all=true
    local install_python_flag=false
    local install_docker_flag=false
    local install_aws_flag=false
    local install_gcp_flag=false
    local install_k8s_flag=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --python-only)
                install_all=false
                install_python_flag=true
                shift
                ;;
            --docker-only)
                install_all=false
                install_docker_flag=true
                shift
                ;;
            --aws-only)
                install_all=false
                install_aws_flag=true
                shift
                ;;
            --gcp-only)
                install_all=false
                install_gcp_flag=true
                shift
                ;;
            --k8s-only)
                install_all=false
                install_k8s_flag=true
                shift
                ;;
            --all)
                install_all=true
                shift
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 检测操作系统
    detect_os
    
    # 根据选项安装依赖
    if [ "$install_all" = true ] || [ "$install_python_flag" = true ]; then
        install_python
        create_venv
    fi
    
    if [ "$install_all" = true ] || [ "$install_docker_flag" = true ]; then
        install_docker
        install_docker_compose
    fi
    
    if [ "$install_all" = true ] || [ "$install_aws_flag" = true ]; then
        install_aws_cli
    fi
    
    if [ "$install_all" = true ] || [ "$install_gcp_flag" = true ]; then
        install_gcloud
    fi
    
    if [ "$install_all" = true ] || [ "$install_k8s_flag" = true ]; then
        install_kubectl
    fi
    
    log_success "所有依赖安装完成！"
    echo ""
    echo "下一步:"
    echo "1. 设置 API Key: export ALPHAGENOME_API_KEY=your_api_key"
    echo "2. 运行测试: python -m pytest src/alphagenome/communication_proxy_test.py -v"
    echo "3. 本地部署: ./scripts/deploy.sh local-docker"
    echo "4. 云部署: ./scripts/deploy.sh aws production us-east-1"
}

# 运行主函数
main "$@" 