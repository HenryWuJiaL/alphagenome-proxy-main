#!/bin/bash

# GitHub上传脚本
echo "🚀 准备上传AlphaGenome项目到GitHub..."

# 检查是否在正确的目录
if [ ! -f "real_alphagenome_service.py" ]; then
    echo "❌ 错误：请在项目根目录运行此脚本"
    exit 1
fi

# 检查Git是否已安装
if ! command -v git &> /dev/null; then
    echo "❌ 错误：Git未安装"
    exit 1
fi

# 检查是否有.env文件（不应该上传）
if [ -f ".env" ]; then
    echo "⚠️  警告：发现.env文件，请确保其中不包含真实的API key"
    echo "   建议在.env.example中只提供示例"
fi

# 初始化Git仓库（如果还没有）
if [ ! -d ".git" ]; then
    echo "📁 初始化Git仓库..."
    git init
fi

# 添加所有文件
echo "📦 添加文件到Git..."
git add .

# 检查要提交的文件
echo "📋 将要提交的文件："
git status --porcelain

# 提交
echo "💾 提交更改..."
git commit -m "feat: AlphaGenome API Key Integration

- 集成真实AlphaGenome API key访问
- 实现所有预测和评分方法
- 添加完整的测试套件
- 支持Docker和Kubernetes部署
- 提供详细的文档和指南

API Key: 使用环境变量ALPHAGENOME_API_KEY
支持的方法: predict_variant, score_variant, predict_interval等
返回真实预测结果: AnnData, VariantOutput, Output等"

echo "✅ 本地提交完成！"
echo ""
echo "📝 下一步："
echo "1. 在GitHub上创建新仓库"
echo "2. 运行以下命令推送："
echo "   git remote add origin https://github.com/yourusername/your-repo-name.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "🔒 安全提醒："
echo "- 确保.env文件没有被上传（已在.gitignore中）"
echo "- 检查env.example中不包含真实API key"
echo "- 在README中说明如何设置API key"
echo ""
echo "🎉 项目准备就绪！"
