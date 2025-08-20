# AlphaGenome Proxy - Google Cloud Deployment Guide

## Overview

This comprehensive guide will walk you through deploying the AlphaGenome Proxy service on Google Cloud Platform using Docker containerization. The deployment includes a FastAPI backend service with Nginx reverse proxy and web interface.

## Prerequisites

### Local Environment Requirements
- Google Cloud CLI (gcloud)
- Git
- Text editor (VS Code, nano, vim, etc.)
- Valid Google Cloud account with billing enabled

### Google Cloud Requirements
- Active Google Cloud project
- Compute Engine API enabled
- Sufficient quota for VM instances
- Valid AlphaGenome API key

## Architecture

```
Internet -> Google Cloud VM -> Nginx (80/443) -> AlphaGenome API (8000)
                                    |
                              Web Interface (HTML)
```

- **Nginx**: Reverse proxy, serves web interface and routes API requests
- **AlphaGenome API**: Core prediction service running on FastAPI
- **Docker**: Containerized deployment for consistency and portability

## Step-by-Step Deployment

### Step 1: Local Environment Setup

1. **Install Google Cloud CLI**
   ```bash
   # macOS
   brew install google-cloud-sdk
   
   # Linux (Ubuntu/Debian)
   curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
   echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
   sudo apt-get update && sudo apt-get install google-cloud-cli
   
   # Windows
   # Download from: https://cloud.google.com/sdk/docs/install
   ```

2. **Authenticate with Google Cloud**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

3. **Set Project Configuration**
   ```bash
   # List available projects
   gcloud projects list
   
   # Set your project ID
   gcloud config set project YOUR_PROJECT_ID
   
   # Verify configuration
   gcloud config list
   ```

### Step 2: Enable Required APIs

```bash
# Enable Compute Engine API
gcloud services enable compute.googleapis.com

# Enable Cloud Build API (optional, for advanced deployments)
gcloud services enable cloudbuild.googleapis.com
```

### Step 3: Configure Environment Variables

1. **Create Environment File**
   ```bash
   # Copy example environment file
   cp env.example .env
   
   # Edit environment file
   nano .env
   ```

2. **Set Required Variables**
   ```bash
   # AlphaGenome API Configuration
   ALPHAGENOME_API_KEY=your_real_alphagenome_api_key_here
   
   # Service Configuration
   API_KEY_HEADER=Authorization
   API_KEY_PREFIX=Bearer
   
   # Docker Configuration
   COMPOSE_PROJECT_NAME=alphagenome-proxy
   
   # Logging Configuration
   LOG_LEVEL=INFO
   
   # Production Configuration
   DOMAIN=your-domain.com
   SSL_EMAIL=your-email@example.com
   ```

### Step 4: Create VM Instance

1. **Set Deployment Variables**
   ```bash
   PROJECT_ID=$(gcloud config get-value project)
   ZONE="us-central1-a"
   MACHINE_TYPE="e2-standard-2"
   ```

2. **Create VM with Startup Script**
   ```bash
   gcloud compute instances create alphagenome-proxy \
       --zone=$ZONE \
       --machine-type=$MACHINE_TYPE \
       --image-family=debian-11 \
       --image-project=debian-cloud \
       --tags=http-server,https-server \
       --metadata=startup-script='#! /bin/bash
           # Update system
           apt-get update
           
           # Install system dependencies
           apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release git nano
           
           # Install Docker
           curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
           echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
           apt-get update
           apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
           
           # Start and enable Docker
           systemctl start docker
           systemctl enable docker
           
           # Create application directory
           mkdir -p /opt/alphagenome
           chown -R $USER:$USER /opt/alphagenome'
   ```

### Step 5: Configure Firewall Rules

```bash
# Allow HTTP traffic
gcloud compute firewall-rules create allow-http \
    --allow tcp:80 \
    --target-tags=http-server \
    --description="Allow HTTP traffic" \
    --quiet

# Allow HTTPS traffic
gcloud compute firewall-rules create allow-https \
    --allow tcp:443 \
    --target-tags=https-server \
    --description="Allow HTTPS traffic" \
    --quiet

# Allow SSH access (optional, for debugging)
gcloud compute firewall-rules create allow-ssh \
    --allow tcp:22 \
    --source-ranges=0.0.0.0/0 \
    --description="Allow SSH access" \
    --quiet
```

### Step 6: Deploy Application

1. **Get VM IP Address**
   ```bash
   INSTANCE_IP=$(gcloud compute instances describe alphagenome-proxy --zone=$ZONE --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
   echo "VM IP Address: $INSTANCE_IP"
   ```

2. **Upload Application Files**
   ```bash
   # Create deployment package
   tar -czf alphagenome-deploy.tar.gz . --exclude=venv --exclude=.git --exclude=*.tar.gz
   
   # Upload to VM
   gcloud compute scp alphagenome-deploy.tar.gz alphagenome-proxy:~/ --zone=$ZONE
   ```

3. **SSH to VM and Deploy**
   ```bash
   gcloud compute ssh alphagenome-proxy --zone=$ZONE
   ```

4. **On VM, Extract and Deploy**
   ```bash
   # Extract application files
   tar -xzf alphagenome-deploy.tar.gz
   cd alphagenome-main\ 2
   
   # Configure environment
   cp env.example .env
   nano .env  # Set your real API key
   
   # Build and start services
   docker-compose up -d --build
   
   # Verify deployment
   docker-compose ps
   ```

### Step 7: Verify Deployment

1. **Check Service Status**
   ```bash
   # On VM
   docker-compose ps
   docker-compose logs
   
   # Test health endpoint
   curl http://localhost/health
   ```

2. **Test External Access**
   ```bash
   # From local machine
   curl http://$INSTANCE_IP/health
   curl http://$INSTANCE_IP/api/docs
   ```

3. **Access Web Interface**
   Open browser and navigate to: `http://$INSTANCE_IP`

## Service Management

### Monitoring Services

```bash
# SSH to VM
gcloud compute ssh alphagenome-proxy --zone=$ZONE

# Check service status
docker-compose ps

# View logs
docker-compose logs -f

# Monitor resources
docker stats
```

### Updating Services

```bash
# On VM
cd /opt/alphagenome/alphagenome-main\ 2

# Pull latest changes (if using git)
git pull

# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

### Scaling Services

```bash
# Scale API service (if needed)
docker-compose up -d --scale alphagenome-proxy=2

# Check scaled services
docker-compose ps
```

## Production Configuration

### SSL/TLS Setup

1. **Generate SSL Certificate**
   ```bash
   # Install certbot
   sudo apt-get install certbot python3-certbot-nginx
   
   # Generate certificate
   sudo certbot --nginx -d your-domain.com
   ```

2. **Update Nginx Configuration**
   ```bash
   # Edit nginx.conf to include SSL
   nano nginx.conf
   ```

3. **Restart Services**
   ```bash
   docker-compose restart nginx
   ```

### Domain Configuration

1. **Update DNS Records**
   - Add A record pointing to VM IP
   - Add CNAME for www subdomain

2. **Update Nginx Configuration**
   ```nginx
   server {
       listen 80;
       server_name your-domain.com www.your-domain.com;
       # ... rest of configuration
   }
   ```

### Backup Strategy

```bash
# Create backup script
cat > backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/backups"
mkdir -p $BACKUP_DIR

# Backup application data
tar -czf $BACKUP_DIR/alphagenome_$DATE.tar.gz /opt/alphagenome

# Backup environment variables
cp .env $BACKUP_DIR/env_$DATE

echo "Backup completed: $BACKUP_DIR/alphagenome_$DATE.tar.gz"
EOF

chmod +x backup.sh
```

## Troubleshooting

### Common Issues

1. **Service Won't Start**
   ```bash
   # Check logs
   docker-compose logs
   
   # Check environment variables
   cat .env
   
   # Restart Docker
   sudo systemctl restart docker
   ```

2. **API Key Issues**
   ```bash
   # Test API key
   curl -H "Authorization: Bearer YOUR_API_KEY" \
        http://localhost/api/health
   ```

3. **Port Conflicts**
   ```bash
   # Check port usage
   netstat -tulpn | grep :80
   netstat -tulpn | grep :8000
   ```

4. **Resource Issues**
   ```bash
   # Check system resources
   free -h
   df -h
   docker system df
   ```

### Performance Optimization

1. **Resource Limits**
   ```yaml
   # In docker-compose.prod.yml
   deploy:
     resources:
       limits:
         memory: 2G
         cpus: '1.0'
   ```

2. **Log Rotation**
   ```yaml
   logging:
     driver: "json-file"
     options:
       max-size: "10m"
       max-file: "3"
   ```

3. **Health Checks**
   ```yaml
   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
     interval: 30s
     timeout: 10s
     retries: 3
   ```

## Cost Management

### Estimated Costs (US Central)
- **e2-standard-2 VM**: $50-70/month
- **Network Egress**: $0.12/GB
- **Persistent Disk**: $0.08/GB/month
- **Total Estimated**: $60-100/month

### Cost Optimization
- Use preemptible instances for development
- Implement auto-shutdown for non-production
- Monitor usage with Cloud Monitoring
- Set up billing alerts

## Security Best Practices

1. **API Key Security**
   - Store keys in environment variables
   - Rotate keys regularly
   - Use least privilege principle

2. **Network Security**
   - Restrict firewall rules
   - Use VPC networks
   - Implement SSL/TLS

3. **Container Security**
   - Use non-root users
   - Regular security updates
   - Scan for vulnerabilities

## Maintenance

### Regular Tasks
- Monitor service logs
- Update system packages
- Rotate logs
- Check disk space
- Review security updates

### Automated Maintenance
```bash
# Create maintenance script
cat > maintenance.sh << 'EOF'
#!/bin/bash
# Update system packages
sudo apt-get update && sudo apt-get upgrade -y

# Clean Docker
docker system prune -f

# Rotate logs
docker-compose logs --tail=1000 > /var/log/alphagenome.log

# Check disk usage
df -h | grep -E 'Use%|/$'
EOF

chmod +x maintenance.sh
```

## Support and Resources

### Documentation
- [Google Cloud Documentation](https://cloud.google.com/docs)
- [Docker Documentation](https://docs.docker.com)
- [FastAPI Documentation](https://fastapi.tiangolo.com)

### Monitoring Tools
- Google Cloud Monitoring
- Docker stats
- Custom monitoring scripts

### Contact Information
For technical support or questions about this deployment guide, please refer to the project documentation or create an issue in the project repository.

## Conclusion

This guide provides a comprehensive approach to deploying the AlphaGenome Proxy service on Google Cloud Platform. The containerized approach ensures consistency across environments and simplifies maintenance. Regular monitoring and updates will ensure optimal performance and security.

Remember to:
- Keep your API keys secure
- Monitor resource usage
- Implement proper backup strategies
- Stay updated with security patches
- Document any custom configurations
