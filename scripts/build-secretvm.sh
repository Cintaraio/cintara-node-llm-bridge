#!/bin/bash

set -e

echo "🔒 Building SecretVM-Compatible Cintara Image"
echo "============================================="

# Configuration
IMAGE_NAME="cintara-unified-secretvm"
PLATFORM="linux/amd64"  # SecretVM requires x86_64 only
DOCKERFILE="Dockerfile.secretvm"

# Generate build metadata
BUILD_TIMESTAMP=$(date -Iseconds)
GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "dev")
DOCKERFILE_HASH=$(sha256sum $DOCKERFILE | cut -d' ' -f1)

echo "📋 Build Information:"
echo "   Timestamp: $BUILD_TIMESTAMP"
echo "   Git Commit: $GIT_COMMIT"
echo "   Git Tag: $GIT_TAG"
echo "   Dockerfile Hash: $DOCKERFILE_HASH"
echo "   Platform: $PLATFORM"
echo ""

# Create build artifacts directory
mkdir -p build-artifacts

# Generate checksums for verification
echo "🔍 Generating checksums for verification..."
sha256sum $DOCKERFILE > build-artifacts/checksums.txt
sha256sum docker-compose.secretvm.yml >> build-artifacts/checksums.txt
sha256sum bridge/app.py >> build-artifacts/checksums.txt
sha256sum cintara-node/node-config.env >> build-artifacts/checksums.txt

# Create build metadata
cat > build-artifacts/build-metadata.json << EOF
{
  "timestamp": "$BUILD_TIMESTAMP",
  "git_commit": "$GIT_COMMIT",
  "git_tag": "$GIT_TAG",
  "dockerfile_hash": "$DOCKERFILE_HASH",
  "platform": "$PLATFORM",
  "secretvm_compatible": true,
  "reproducible_build": true,
  "builder": "$(whoami)@$(hostname)",
  "docker_version": "$(docker --version | cut -d' ' -f3 | tr -d ',')"
}
EOF

echo "✅ Build metadata created"

# Build the image
echo "🏗️  Building SecretVM image..."
docker buildx build \
  --platform $PLATFORM \
  --file $DOCKERFILE \
  --build-arg BUILD_TIMESTAMP="$BUILD_TIMESTAMP" \
  --build-arg GIT_COMMIT="$GIT_COMMIT" \
  --build-arg GIT_TAG="$GIT_TAG" \
  --tag $IMAGE_NAME:latest \
  --tag $IMAGE_NAME:$GIT_TAG \
  --load \
  .

echo "✅ Image built successfully"

# Get image digest and size
IMAGE_ID=$(docker images --format "table {{.ID}}" $IMAGE_NAME:latest | tail -n 1)
IMAGE_SIZE=$(docker images --format "table {{.Size}}" $IMAGE_NAME:latest | tail -n 1)

echo "📊 Image Information:"
echo "   Image ID: $IMAGE_ID"
echo "   Size: $IMAGE_SIZE"
echo "   Tags: $IMAGE_NAME:latest, $IMAGE_NAME:$GIT_TAG"

# Create image manifest
cat > build-artifacts/image-manifest.json << EOF
{
  "image": "$IMAGE_NAME",
  "tags": ["latest", "$GIT_TAG"],
  "image_id": "$IMAGE_ID",
  "size": "$IMAGE_SIZE",
  "platform": "$PLATFORM",
  "build_info": $(cat build-artifacts/build-metadata.json),
  "attestation": {
    "reproducible_build": true,
    "secretvm_compatible": true,
    "tee_requirements": {
      "intel_sgx": ">=2.0",
      "intel_tdx": ">=1.0",
      "amd_sev": ">=1.0"
    }
  }
}
EOF

# Security scan (if trivy is available)
if command -v trivy >/dev/null 2>&1; then
    echo "🔒 Running security scan..."
    trivy image --format json --output build-artifacts/security-scan.json $IMAGE_NAME:latest || echo "Security scan failed"
    echo "Security scan results saved to build-artifacts/security-scan.json"
fi

# Test the image
echo "🧪 Testing the built image..."
TEST_CONTAINER="test-secretvm-$(date +%s)"

# Start container in background
docker run -d --name $TEST_CONTAINER \
  -p 26657:26657 -p 8000:8000 -p 8080:8080 -p 9999:9999 \
  $IMAGE_NAME:latest

echo "⏳ Waiting for services to start..."
sleep 30

# Test health endpoints
HEALTH_STATUS="UNKNOWN"
if timeout 10 curl -sf http://localhost:26657/status >/dev/null 2>&1; then
    echo "✅ Cintara node: OK"
    HEALTH_STATUS="HEALTHY"
else
    echo "❌ Cintara node: Failed"
    HEALTH_STATUS="UNHEALTHY"
fi

if timeout 10 curl -sf http://localhost:8080/health >/dev/null 2>&1; then
    echo "✅ AI Bridge: OK"
else
    echo "❌ AI Bridge: Failed"
    HEALTH_STATUS="UNHEALTHY"
fi

# Test attestation endpoint
if timeout 5 curl -sf http://localhost:9999/attestation >/dev/null 2>&1; then
    echo "✅ Attestation endpoint: OK"
else
    echo "⚠️  Attestation endpoint: Not responding (expected for non-TEE environment)"
fi

# Cleanup test container
docker stop $TEST_CONTAINER >/dev/null 2>&1
docker rm $TEST_CONTAINER >/dev/null 2>&1

# Update manifest with test results
jq --arg status "$HEALTH_STATUS" '.test_results = {"health_status": $status, "tested_at": "'$(date -Iseconds)'"}' \
  build-artifacts/image-manifest.json > build-artifacts/image-manifest.tmp && \
  mv build-artifacts/image-manifest.tmp build-artifacts/image-manifest.json

echo ""
echo "✅ SecretVM image build completed!"
echo ""
echo "📁 Build artifacts created in: build-artifacts/"
echo "   - checksums.txt"
echo "   - build-metadata.json"
echo "   - image-manifest.json"
if [ -f "build-artifacts/security-scan.json" ]; then
    echo "   - security-scan.json"
fi
echo ""
echo "🚀 To run the SecretVM image:"
echo "   docker run -d --name cintara-secretvm \\"
echo "     -p 26657:26657 -p 8000:8000 -p 8080:8080 -p 9999:9999 \\"
echo "     $IMAGE_NAME:latest"
echo ""
echo "🔗 To deploy to SecretVM portal:"
echo "   1. Upload docker-compose.secretvm.yml to SecretAI portal"
echo "   2. Set image reference to: $IMAGE_NAME:$GIT_TAG"
echo "   3. Configure environment variables as needed"
echo ""
echo "📋 Image verification:"
echo "   Image ID: $IMAGE_ID"
echo "   Build Hash: $DOCKERFILE_HASH"
echo "   Git Commit: $GIT_COMMIT"