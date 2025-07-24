# AlphaGenome Communication Proxy Windows 部署脚本
param(
    [string]$Platform = "local-docker",
    [string]$Environment = "production",
    [string]$Region = "us-east-1",
    [switch]$BuildOnly,
    [switch]$Help
)

# 颜色定义
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"

# 日志函数
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor $Blue }
function Write-Success { param([string]$Message) Write-Host "[SUCCESS] $Message" -ForegroundColor $Green }
function Write-Warning { param([string]$Message) Write-Host "[WARNING] $Message" -ForegroundColor $Yellow }
function Write-Error { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor $Red }

# 显示帮助
function Show-Help {
    Write-Host "AlphaGenome Communication Proxy Windows 部署脚本" -ForegroundColor $Blue
    Write-Host "用法: .\deploy.ps1 [选项] [平台]" -ForegroundColor White
    Write-Host "平台: local-docker, aws, gcp, k8s" -ForegroundColor White
    Write-Host "选项: -BuildOnly, -Help" -ForegroundColor White
}

# 检查依赖
function Test-Dependencies {
    Write-Info "检查部署依赖..."
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "请先安装 Docker Desktop"
        exit 1
    }
    Write-Success "所有依赖已满足"
}

# 构建镜像
function Build-DockerImage {
    param([string]$Tag = "alphagenome-proxy:latest")
    Write-Info "构建 Docker 镜像: $Tag"
    docker build -t $Tag .
    Write-Success "Docker 镜像构建成功"
}

# 本地部署
function Deploy-LocalDocker {
    Write-Info "开始本地 Docker 部署..."
    docker-compose down 2>$null
    docker-compose up -d
    Write-Success "本地 Docker 部署成功"
    Write-Info "服务地址: localhost:50051"
}

# 主函数
function Main {
    if ($Help) { Show-Help; return }
    Test-Dependencies
    if ($BuildOnly) { Build-DockerImage; return }
    
    switch ($Platform) {
        "local-docker" { Deploy-LocalDocker }
        default { Write-Error "不支持的平台: $Platform"; Show-Help }
    }
}

Main 