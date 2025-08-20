#!/bin/bash

# AlphaGenome Proxy Google Cloud Deployment Script
# Usage: ./deploy-to-gcp.sh

set -e

echo "Starting AlphaGenome Proxy deployment to Google Cloud..."

# Check gcloud CLI
if ! command -v gcloud &> /dev/null; then
    echo "ERROR: Please install Google Cloud CLI first"
    echo "Install guide: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if logged in
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "ERROR: Please login to Google Cloud first"
    echo "Run: gcloud auth login"
    exit 1
fi

# Set project ID
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo "ERROR: Please set Google Cloud project"
    echo "Run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "Using project: $PROJECT_ID"

# Set zone
ZONE="us-central1-a"
echo "Using zone: $ZONE"

# Create VM instance
echo "Creating VM instance..."
gcloud compute instances create alphagenome-proxy \
    --zone=$ZONE \
    --machine-type=e2-standard-2 \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --tags=http-server,https-server \
    --metadata=startup-script='#! /bin/bash
        # Install Docker
        apt-get update
        apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Start Docker service
        systemctl start docker
        systemctl enable docker
        
        # Install git
        apt-get install -y git'

# Configure firewall
echo "Configuring firewall rules..."
gcloud compute firewall-rules create allow-http \
    --allow tcp:80 \
    --target-tags=http-server \
    --description="Allow HTTP traffic" \
    --quiet

gcloud compute firewall-rules create allow-https \
    --allow tcp:443 \
    --target-tags=https-server \
    --description="Allow HTTPS traffic" \
    --quiet

# Get instance IP
echo "Getting instance IP address..."
INSTANCE_IP=$(gcloud compute instances describe alphagenome-proxy --zone=$ZONE --format="value(networkInterfaces[0].accessConfigs[0].natIP)")

echo "VM instance created successfully!"
echo "Instance IP: $INSTANCE_IP"
echo "Access URL: http://$INSTANCE_IP"

# Wait for instance to start
echo "Waiting for instance to start..."
sleep 60

# Deploy application
echo "Deploying AlphaGenome Proxy application..."
gcloud compute ssh alphagenome-proxy --zone=$ZONE --command="
    # Clone project
    git clone https://github.com/your-username/alphagenome-main.git
    cd alphagenome-main
    
    # Configure environment variables
    cp env.example .env
    echo 'ALPHAGENOME_API_KEY=your_api_key_here' > .env
    echo 'COMPOSE_PROJECT_NAME=alphagenome-proxy' >> .env
    
    # Build and start services
    docker-compose up -d --build
    
    # Check service status
    docker-compose ps
"

echo "Deployment completed!"
echo ""
echo "Next steps:"
echo "1. SSH to instance: gcloud compute ssh alphagenome-proxy --zone=$ZONE"
echo "2. Edit .env file with real API Key: nano .env"
echo "3. Restart services: docker-compose restart"
echo "4. Access Web interface: http://$INSTANCE_IP"
echo "5. View API docs: http://$INSTANCE_IP/api/docs"
echo ""
echo "Common commands:"
echo "  Check service status: docker-compose ps"
echo "  View logs: docker-compose logs -f"
echo "  Restart services: docker-compose restart"
echo "  Update services: git pull && docker-compose up -d --build"
echo ""
echo "Service URLs:"
echo "  Web interface: http://$INSTANCE_IP"
echo "  API endpoints: http://$INSTANCE_IP/api/"
echo "  Health check: http://$INSTANCE_IP/health"
