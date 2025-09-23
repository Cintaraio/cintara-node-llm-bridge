# 🏗️ Building Cintara Images on EC2

**Complete guide for building and pushing Cintara Docker images to AWS ECR using EC2**

## 🚨 Why Build on EC2?

- **Platform Compatibility**: SecretVM requires `linux/amd64` architecture
- **Build Performance**: Faster builds on native Linux
- **AWS Integration**: Better ECR connectivity and IAM roles
- **Avoid Mac Issues**: No Docker buildx or architecture conflicts

---

## 🚀 Quick Start

### **Step 1: Launch EC2 Instance**

**Recommended Instance:**
- **Type**: `t3.medium` or `t3.large` (2-4 vCPU, 4-8 GB RAM)
- **AMI**: Amazon Linux 2 or Ubuntu 22.04 LTS
- **Storage**: 20 GB GP3 (minimum)
- **Security Group**: Allow SSH (22) inbound

**Launch Command (AWS CLI):**
```bash
aws ec2 run-instances \
    --image-id ami-0abcdef1234567890 \
    --instance-type t3.medium \
    --key-name your-key-pair \
    --security-group-ids sg-12345678 \
    --subnet-id subnet-12345678 \
    --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":20,"VolumeType":"gp3"}}]' \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cintara-build}]'
```

### **Step 2: Connect to EC2**
```bash
# SSH to your instance
ssh -i your-key.pem ec2-user@<instance-ip>
# or for Ubuntu:
ssh -i your-key.pem ubuntu@<instance-ip>
```

### **Step 3: Run Automated Build**
```bash
# Download and run the build script
curl -sSL https://raw.githubusercontent.com/Cintaraio/cintara-node-llm-bridge/feat/unified-automated-setup/scripts/build-on-ec2.sh | sudo bash

# Or manually download and run:
wget https://raw.githubusercontent.com/Cintaraio/cintara-node-llm-bridge/feat/unified-automated-setup/scripts/build-on-ec2.sh
chmod +x build-on-ec2.sh
sudo ./build-on-ec2.sh
```

---

## 🔧 Manual Setup (Alternative)

### **Step 1: Install Dependencies**
```bash
# Update system
sudo yum update -y  # Amazon Linux
# sudo apt update && sudo apt upgrade -y  # Ubuntu

# Install Docker
sudo amazon-linux-extras install docker -y  # Amazon Linux
sudo service docker start
sudo chkconfig docker on

# Add user to docker group
sudo usermod -a -G docker ec2-user
# Logout and login again for group changes

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install AWS CLI (if not present)
sudo yum install -y awscli

# Install Git
sudo yum install -y git
```

### **Step 2: Configure AWS Credentials**

**Option A: Using IAM Role (Recommended)**
```bash
# Attach an IAM role with ECR permissions to your EC2 instance
# No additional configuration needed
aws sts get-caller-identity  # Verify
```

**Option B: Using AWS CLI**
```bash
aws configure
# Enter your AWS credentials when prompted
```

**Option C: Using Environment Variables**
```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1
```

### **Step 3: Clone Repository**
```bash
# Create working directory
mkdir -p ~/cintara-build
cd ~/cintara-build

# Clone repository
git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
cd cintara-node-llm-bridge

# Switch to correct branch
git checkout feat/unified-automated-setup
```

### **Step 4: Build and Push Images**
```bash
# Login to ECR
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws

# Set variables
GIT_COMMIT=$(git rev-parse --short HEAD)
BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
IMAGE_NAME="public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified"

# Build unified image
docker build \
    --platform linux/amd64 \
    --build-arg BUILD_TIMESTAMP="$BUILD_TIMESTAMP" \
    --build-arg GIT_COMMIT="$GIT_COMMIT" \
    -f Dockerfile.unified \
    -t "$IMAGE_NAME:latest" \
    -t "$IMAGE_NAME:$GIT_COMMIT" \
    .

# Push to ECR
docker push "$IMAGE_NAME:latest"
docker push "$IMAGE_NAME:$GIT_COMMIT"

# Build SecretVM image
docker build \
    --platform linux/amd64 \
    --build-arg BUILD_TIMESTAMP="$BUILD_TIMESTAMP" \
    --build-arg GIT_COMMIT="$GIT_COMMIT" \
    -f Dockerfile.secretvm \
    -t "$IMAGE_NAME:secretvm-latest" \
    -t "$IMAGE_NAME:secretvm-$GIT_COMMIT" \
    .

# Push SecretVM image
docker push "$IMAGE_NAME:secretvm-latest"
docker push "$IMAGE_NAME:secretvm-$GIT_COMMIT"
```

---

## 📋 Required IAM Permissions

Your EC2 instance needs these ECR permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr-public:GetAuthorizationToken",
                "ecr-public:BatchCheckLayerAvailability",
                "ecr-public:GetDownloadUrlForLayer",
                "ecr-public:BatchGetImage",
                "ecr-public:InitiateLayerUpload",
                "ecr-public:UploadLayerPart",
                "ecr-public:CompleteLayerUpload",
                "ecr-public:PutImage"
            ],
            "Resource": "*"
        }
    ]
}
```

---

## 🔍 Troubleshooting

### **Build Fails - Insufficient Space**
```bash
# Check disk space
df -h

# Clean up Docker
docker system prune -f

# Increase EC2 storage if needed
```

### **Permission Denied (Docker)**
```bash
# Add user to docker group
sudo usermod -a -G docker $USER

# Logout and login again
exit
# SSH back in
```

### **AWS Authentication Fails**
```bash
# Check credentials
aws sts get-caller-identity

# Re-configure if needed
aws configure

# Or use IAM role (preferred)
```

### **ECR Login Fails**
```bash
# Make sure you're in us-east-1 region
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws

# Check if repository exists
aws ecr-public describe-repositories --region us-east-1
```

### **Build Takes Too Long**
```bash
# Use larger instance type
# t3.large or t3.xlarge for faster builds

# Check build progress
docker logs <container-id>
```

---

## 🧪 Testing Built Images

### **Test Locally on EC2**
```bash
# Run the unified image
docker run --rm -d --name test-cintara \
    -p 26657:26657 -p 8000:8000 -p 8080:8080 \
    public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified:latest

# Wait a few minutes, then test endpoints
curl http://localhost:26657/status
curl http://localhost:8000/health
curl http://localhost:8080/health

# Check logs
docker logs test-cintara

# Clean up
docker stop test-cintara
```

### **Test with Docker Compose**
```bash
# Update docker-compose.yml to use ECR image
# image: public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified:latest

# Start with compose
docker-compose up -d

# Test endpoints
curl http://localhost:26657/status
curl http://localhost:8000/health
curl http://localhost:8080/health
```

---

## 🎯 Expected Results

### **Successful Build Output:**
```
✅ Build completed successfully!
🚀 Pushing image to ECR...
✅ Image pushed successfully!

📋 Available images:
   - public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified:latest
   - public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified:e9d7f90
   - public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified:secretvm-latest
   - public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified:secretvm-e9d7f90
```

### **ECR Repository:**
- **Repository**: `public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified`
- **Tags**: `latest`, `secretvm-latest`, commit hashes
- **Platform**: `linux/amd64`

---

## 🧹 Cleanup

### **Clean EC2 Instance**
```bash
# Remove Docker images
docker rmi $(docker images -q)

# Remove build files
rm -rf ~/cintara-build

# Stop Docker service
sudo service docker stop
```

### **Terminate EC2 Instance**
```bash
# From your local machine
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0
```

---

## 🎉 Next Steps

After successful build:

1. **Update docker-compose files** to use ECR images
2. **Test deployment** with `docker-compose up`
3. **Share with Secret Network team** for SecretVM validation
4. **Deploy to production** SecretVM environment

**Image ready for use:**
```yaml
image: public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified:latest
```