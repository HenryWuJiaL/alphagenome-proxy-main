#!/bin/bash

# AlphaGenome Proxy Quick Deploy Script
# Supports: AWS EC2, GCP Cloud Run, Azure Container Instances, DigitalOcean

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Setup environment
setup_environment() {
    print_status "Setting up environment..."
    
    if [ ! -f .env ]; then
        if [ -f env.example ]; then
            cp env.example .env
            print_warning ".env file created from example. Please edit it with your API key."
            print_status "Edit .env file and set ALPHAGENOME_API_KEY, then run this script again."
            exit 1
        else
            print_error "env.example file not found. Please create .env file manually."
            exit 1
        fi
    fi
    
    # Load environment variables
    source .env
    
    # Check if API key is set
    if [ -z "$ALPHAGENOME_API_KEY" ] || [ "$ALPHAGENOME_API_KEY" = "your_api_key_here" ]; then
        print_error "Please set ALPHAGENOME_API_KEY in .env file"
        exit 1
    fi
    
    print_success "Environment setup completed"
}

# Build Docker image
build_image() {
    print_status "Building Docker image..."
    docker build -t alphagenome-proxy .
    print_success "Docker image built successfully"
}

# Deploy locally
deploy_local() {
    print_status "Deploying locally with Docker Compose..."
    
    if [ -f docker-compose.yml ]; then
        docker-compose up -d
        print_success "Local deployment completed"
        print_status "Services running on:"
        print_status "  - JSON Service: http://localhost:8000"
        print_status "  - gRPC Proxy: localhost:50051"
    else
        print_error "docker-compose.yml not found"
        exit 1
    fi
}

# Deploy to AWS ECR
deploy_aws_ecr() {
    print_status "Deploying to AWS ECR..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not installed. Please install AWS CLI first."
        exit 1
    fi
    
    read -p "Enter your AWS account ID: " AWS_ACCOUNT_ID
    read -p "Enter your AWS region (e.g., us-east-1): " AWS_REGION
    
    # Login to ECR
    print_status "Logging into ECR..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
    
    # Create repository if it doesn't exist
    aws ecr create-repository --repository-name alphagenome-proxy --region $AWS_REGION 2>/dev/null || true
    
    # Tag and push image
    docker tag alphagenome-proxy:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/alphagenome-proxy:latest
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/alphagenome-proxy:latest
    
    print_success "Image pushed to ECR successfully"
    print_status "Image URI: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/alphagenome-proxy:latest"
}

# Deploy to GCP Cloud Run
deploy_gcp_cloudrun() {
    print_status "Deploying to GCP Cloud Run..."
    
    if ! command -v gcloud &> /dev/null; then
        print_error "Google Cloud SDK not installed. Please install gcloud first."
        exit 1
    fi
    
    read -p "Enter your GCP project ID: " GCP_PROJECT_ID
    read -p "Enter your GCP region (e.g., us-central1): " GCP_REGION
    
    # Build and deploy
    print_status "Building and deploying to Cloud Run..."
    gcloud builds submit --tag gcr.io/$GCP_PROJECT_ID/alphagenome-proxy
    
    gcloud run deploy alphagenome-proxy \
        --image gcr.io/$GCP_PROJECT_ID/alphagenome-proxy \
        --platform managed \
        --region $GCP_REGION \
        --allow-unauthenticated \
        --port 8000 \
        --set-env-vars ALPHAGENOME_API_KEY=$ALPHAGENOME_API_KEY \
        --memory 1Gi \
        --cpu 1 \
        --max-instances 10
    
    print_success "Deployed to Cloud Run successfully"
}

# Deploy to Azure Container Instances
deploy_azure_aci() {
    print_status "Deploying to Azure Container Instances..."
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI not installed. Please install Azure CLI first."
        exit 1
    fi
    
    read -p "Enter your Azure resource group name: " AZURE_RG
    read -p "Enter your Azure location (e.g., eastus): " AZURE_LOCATION
    
    # Create resource group if it doesn't exist
    az group create --name $AZURE_RG --location $AZURE_LOCATION 2>/dev/null || true
    
    # Create container instance
    az container create \
        --resource-group $AZURE_RG \
        --name alphagenome-proxy \
        --image alphagenome-proxy:latest \
        --ports 50051 8000 \
        --environment-variables ALPHAGENOME_API_KEY=$ALPHAGENOME_API_KEY \
        --dns-name-label alphagenome-proxy-$RANDOM \
        --location $AZURE_LOCATION \
        --memory 1 \
        --cpu 1
    
    print_success "Deployed to Azure Container Instances successfully"
}

# Main deployment menu
main_menu() {
    echo ""
    echo "=== AlphaGenome Proxy Deployment Menu ==="
    echo "1. Deploy locally with Docker Compose"
    echo "2. Deploy to AWS ECR"
    echo "3. Deploy to GCP Cloud Run"
    echo "4. Deploy to Azure Container Instances"
    echo "5. Build Docker image only"
    echo "6. Exit"
    echo ""
    read -p "Select deployment option (1-6): " choice
    
    case $choice in
        1)
            deploy_local
            ;;
        2)
            deploy_aws_ecr
            ;;
        3)
            deploy_gcp_cloudrun
            ;;
        4)
            deploy_azure_aci
            ;;
        5)
            build_image
            ;;
        6)
            print_status "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid option. Please select 1-6."
            main_menu
            ;;
    esac
}

# Main execution
main() {
    echo "AlphaGenome Proxy Quick Deploy Script"
    echo "====================================="
    
    check_prerequisites
    setup_environment
    build_image
    
    if [ "$1" = "--local" ]; then
        deploy_local
    elif [ "$1" = "--aws" ]; then
        deploy_aws_ecr
    elif [ "$1" = "--gcp" ]; then
        deploy_gcp_cloudrun
    elif [ "$1" = "--azure" ]; then
        deploy_azure_aci
    else
        main_menu
    fi
    
    print_success "Deployment completed successfully!"
}

# Run main function with arguments
main "$@"
