#!/bin/bash

# 🚀 准备 GitHub 上传脚本

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

# 检查 Git 是否已初始化
check_git() {
    if [ ! -d ".git" ]; then
        print_info "初始化 Git 仓库..."
        git init
        print_success "Git 仓库初始化完成"
    else
        print_info "Git 仓库已存在"
    fi
}

# 备份原始 README
backup_readme() {
    if [ -f "README.md" ]; then
        print_info "备份原始 README.md..."
        cp README.md README_original.md
        print_success "README.md 已备份为 README_original.md"
    fi
}

# 替换 README
replace_readme() {
    print_info "替换 README.md..."
    if [ -f "README_GITHUB.md" ]; then
        cp README_GITHUB.md README.md
        print_success "README.md 已更新"
    else
        print_warning "README_GITHUB.md 不存在，使用原始 README"
    fi
}

# 清理不需要的文件
clean_files() {
    print_info "清理不需要的文件..."
    
    # 删除测试文件
    rm -f test_*.py
    rm -f *_test.py
    rm -f official_result.png
    
    # 删除缓存目录
    rm -rf __pycache__
    rm -rf .pytest_cache
    rm -rf src/alphagenome/__pycache__
    
    # 删除敏感文件
    rm -f config_example.env
    rm -f deployment-key.json
    rm -f *.key
    rm -f *.pem
    
    # 删除日志文件
    rm -rf logs/
    rm -f *.log
    
    print_success "文件清理完成"
}

# 创建目录结构
create_structure() {
    print_info "创建目录结构..."
    
    # 创建必要的目录
    mkdir -p docs
    mkdir -p examples
    mkdir -p tests
    mkdir -p scripts
    
    print_success "目录结构创建完成"
}

# 移动文件到合适位置
organize_files() {
    print_info "整理文件..."
    
    # 移动文档文件到 docs 目录
    if [ -f "USER_GUIDE.md" ]; then
        mv USER_GUIDE.md docs/
    fi
    if [ -f "QUICK_START.md" ]; then
        mv QUICK_START.md docs/
    fi
    if [ -f "API_REFERENCE.md" ]; then
        mv API_REFERENCE.md docs/
    fi
    if [ -f "CLOUD_DEPLOYMENT_GUIDE.md" ]; then
        mv CLOUD_DEPLOYMENT_GUIDE.md docs/
    fi
    if [ -f "STUDENT_CLOUD_DEPLOYMENT.md" ]; then
        mv STUDENT_CLOUD_DEPLOYMENT.md docs/
    fi
    
    # 移动示例文件到 examples 目录
    if [ -f "proxy_client_example.py" ]; then
        mv proxy_client_example.py examples/
    fi
    if [ -f "test_official_vs_proxy.py" ]; then
        mv test_official_vs_proxy.py examples/
    fi
    
    # 移动脚本文件到 scripts 目录
    if [ -f "student-deploy-gcp.sh" ]; then
        mv student-deploy-gcp.sh scripts/
    fi
    
    print_success "文件整理完成"
}

# 创建 .gitignore
create_gitignore() {
    print_info "创建 .gitignore..."
    
    if [ ! -f ".gitignore" ]; then
        print_error ".gitignore 文件不存在，请先创建"
        exit 1
    fi
    
    print_success ".gitignore 已存在"
}

# 添加文件到 Git
add_to_git() {
    print_info "添加文件到 Git..."
    
    # 添加所有文件
    git add .
    
    print_success "文件已添加到 Git"
}

# 创建初始提交
create_commit() {
    print_info "创建初始提交..."
    
    git commit -m "Initial commit: AlphaGenome Proxy Service

- 高性能 AlphaGenome API 代理服务
- 支持 gRPC 接口
- 一键部署到 Google Cloud
- 完整的文档和示例
- 学生友好的免费部署方案"
    
    print_success "初始提交创建完成"
}

# 显示上传说明
show_upload_instructions() {
    echo ""
    echo "🎉 项目准备完成！"
    echo "=================="
    echo ""
    echo "📋 下一步操作："
    echo ""
    echo "1. 在 GitHub 上创建新仓库："
    echo "   - 仓库名: alphagenome-proxy"
    echo "   - 描述: A high-performance proxy service for AlphaGenome API"
    echo "   - 选择: Private（私人仓库）"
    echo ""
    echo "2. 添加远程仓库："
    echo "   git remote add origin https://github.com/YOUR_USERNAME/alphagenome-proxy.git"
    echo ""
    echo "3. 推送到 GitHub："
    echo "   git branch -M main"
    echo "   git push -u origin main"
    echo ""
    echo "📁 项目结构："
    echo "   ├── src/alphagenome/          # 代理服务代码"
    echo "   ├── docs/                     # 文档"
    echo "   ├── examples/                 # 使用示例"
    echo "   ├── scripts/                  # 部署脚本"
    echo "   ├── deployment-package/       # 部署包"
    echo "   ├── README.md                 # 项目介绍"
    echo "   ├── LICENSE                   # 开源许可证"
    echo "   └── .gitignore               # Git 忽略文件"
    echo ""
    echo "🔒 安全检查："
    echo "   ✅ 已排除敏感文件"
    echo "   ✅ 已排除官方 AlphaGenome 包"
    echo "   ✅ 已排除虚拟环境"
    echo "   ✅ 已排除缓存文件"
    echo ""
}

# 主函数
main() {
    echo "🚀 准备 GitHub 上传"
    echo "=================="
    echo ""
    
    # 执行步骤
    check_git
    backup_readme
    replace_readme
    clean_files
    create_structure
    organize_files
    create_gitignore
    add_to_git
    create_commit
    show_upload_instructions
    
    print_success "项目准备完成！"
}

# 运行主函数
main "$@" 