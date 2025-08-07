#!/bin/bash

# Student Google Cloud One-Click Deployment Script
# AlphaGenome Communication Proxy

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log functions
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

echo "AlphaGenome Student Free Cloud Deployment Script"
echo "================================================"

# Check dependencies
log_info "Checking deployment dependencies..."

# Check Docker
if ! command -v docker &> /dev/null; then
    log_error "Please install Docker first"
    echo "Installation commands:"
    echo "  macOS: brew install docker"
    echo "  Linux: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

# Check Google Cloud SDK
if ! command -v gcloud &> /dev/null; then
    log_error "Please install Google Cloud SDK first"
    echo "Installation commands:"
    echo "  macOS: brew install google-cloud-sdk"
    echo "  Linux: curl https://sdk.cloud.google.com | bash"
    echo "  Then run: gcloud init"
    exit 1
fi

# Check if logged in
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    log_error "Please login to Google Cloud first"
    echo "Run command: gcloud auth login"
    exit 1
fi

log_success "All dependencies satisfied"

# Set variables
export PROJECT_ID=alphagenome-student-$(date +%s)
export ALPHAGENOME_API_KEY=AIzaSyCuzXNdXfyPfQVvrPVvMGt_YmIyI07cnbw
export REGION=us-central1

log_info "Creating project: $PROJECT_ID"

# Create project
if gcloud projects create $PROJECT_ID --quiet; then
    log_success "Project created successfully"
else
    log_error "Project creation failed, project name may already exist"
    export PROJECT_ID=alphagenome-student-$(date +%s)-$(openssl rand -hex 4)
    log_info "Trying with new project name: $PROJECT_ID"
    gcloud projects create $PROJECT_ID --quiet
fi

# Set project
gcloud config set project $PROJECT_ID
log_success "Project setup complete"

# Enable required services
log_info "Enabling Google Cloud services..."
gcloud services enable run.googleapis.com --quiet
gcloud services enable containerregistry.googleapis.com --quiet
log_success "Services enabled"

# Configure Docker authentication
log_info "Configuring Docker authentication..."
gcloud auth configure-docker --quiet
log_success "Docker authentication configured"

# Build Docker image
log_info "Building Docker image..."
if docker build -t gcr.io/$PROJECT_ID/alphagenome-proxy .; then
    log_success "Docker image built successfully"
else
    log_error "Docker image build failed"
    exit 1
fi

# Push image to Google Container Registry
log_info "Pushing image to Google Container Registry..."
if docker push gcr.io/$PROJECT_ID/alphagenome-proxy; then
    log_success "Image pushed successfully"
else
    log_error "Image push failed"
    exit 1
fi

# Deploy to Cloud Run
log_info "Deploying to Google Cloud Run..."
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
    log_success "Deployment successful"
else
    log_error "Deployment failed"
    exit 1
fi

# Get service URL
log_info "Getting service URL..."
SERVICE_URL=$(gcloud run services describe alphagenome-proxy \
  --region $REGION \
  --format 'value(status.url)' \
  --quiet)

if [ -n "$SERVICE_URL" ]; then
    log_success "Service deployment complete!"
    echo ""
    echo "Deployment successful!"
    echo "================================================"
    echo "Service URL: $SERVICE_URL"
    echo "gRPC Endpoint: $SERVICE_URL:50051"
    echo "Project ID: $PROJECT_ID"
    echo "Region: $REGION"
    echo ""
    echo "Testing service:"
    echo "curl -X GET $SERVICE_URL/health"
    echo ""
    echo "Viewing logs:"
    echo "gcloud logs tail --project=$PROJECT_ID --service=alphagenome-proxy"
    echo ""
    echo "Cost information:"
    echo "- Free quota: 200M requests per month"
    echo "- Overage: $0.0000024/request"
    echo "- Student discount: $300 free quota"
    echo ""
    echo "Learning resources:"
    echo "- Google Cloud Learning: https://cloud.google.com/learn"
    echo "- Student discount: https://cloud.google.com/edu"
    echo ""
else
    log_error "Could not get service URL"
    exit 1
fi

# Save configuration information
cat > deployment-info.txt << EOF
AlphaGenome Communication Proxy Deployment Information
================================================"
Deployment Time: $(date)
Project ID: $PROJECT_ID
Service URL: $SERVICE_URL
gRPC Endpoint: $SERVICE_URL:50051
Region: $REGION
API Key: $ALPHAGENOME_API_KEY

Test Command:
curl -X GET $SERVICE_URL/health

Viewing Logs:
gcloud logs tail --project=$PROJECT_ID --service=alphagenome-proxy

Deleting Service:
gcloud run services delete alphagenome-proxy --region=$REGION --quiet
gcloud projects delete $PROJECT_ID --quiet
EOF

log_success "Deployment information saved to deployment-info.txt"

echo ""
echo "Congratulations! Your AlphaGenome Communication Proxy has been successfully deployed to Google Cloud!"
echo "Tip: Remember to check usage regularly to avoid exceeding free quota" 