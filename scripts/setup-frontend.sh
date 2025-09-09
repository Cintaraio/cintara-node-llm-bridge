#!/bin/bash

# Cintara Node Web UI Setup Script for EC2
# This script sets up the React frontend on Ubuntu EC2 instances

set -e

echo "🚀 Starting Cintara Web UI Setup on EC2..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as ubuntu user."
   exit 1
fi

# Update system
print_info "Updating system packages..."
sudo apt update

# Install Node.js 18 LTS
print_info "Installing Node.js 18 LTS..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    print_status "Node.js installed: $(node --version)"
else
    print_status "Node.js already installed: $(node --version)"
fi

# Install npm if not present
if ! command -v npm &> /dev/null; then
    sudo apt-get install -y npm
fi

print_status "npm version: $(npm --version)"

# Navigate to web-ui directory
if [ ! -d "web-ui" ]; then
    print_error "web-ui directory not found. Make sure you're in the cintara-node-llm-bridge directory"
    exit 1
fi

cd web-ui

# Install dependencies
print_info "Installing React dependencies..."
npm install

print_status "Dependencies installed successfully"

# Check if .env file exists, create if not
if [ ! -f ".env" ]; then
    print_info "Creating environment configuration..."
    cat > .env << EOF
REACT_APP_API_URL=http://localhost:8080
GENERATE_SOURCEMAP=false
DISABLE_ESLINT_PLUGIN=true
EOF
    print_status "Environment file created"
fi

# Build the application
print_info "Building React application for production..."
npm run build

print_status "React application built successfully"

# Install PM2 for process management
print_info "Installing PM2 for process management..."
sudo npm install -g pm2

# Install serve for serving static files
print_info "Installing serve package..."
sudo npm install -g serve

print_status "Frontend setup completed successfully!"

echo ""
print_info "🎯 Next Steps:"
echo "1. Start the AI Bridge first: docker compose up bridge -d"
echo "2. Start the frontend: pm2 start 'serve -s build -l 3000' --name cintara-web-ui"
echo "3. Access at: http://localhost:3000"
echo ""
print_info "📖 Management Commands:"
echo "• View logs: pm2 logs cintara-web-ui"
echo "• Restart: pm2 restart cintara-web-ui"
echo "• Stop: pm2 stop cintara-web-ui"
echo "• Delete: pm2 delete cintara-web-ui"
echo ""
print_warning "Make sure the AI Bridge (port 8080) is running before starting the frontend!"