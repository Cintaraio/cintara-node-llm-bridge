#!/bin/bash

set -e

echo "🔐 Setting up GitHub Container Registry (GHCR)"
echo "=============================================="

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it from: https://cli.github.com/"
    echo ""
    echo "Or install via:"
    echo "  macOS: brew install gh"
    echo "  Ubuntu: sudo apt install gh"
    exit 1
fi

# Check if user is logged in to GitHub CLI
if ! gh auth status &> /dev/null; then
    echo "🔑 Please login to GitHub CLI first:"
    echo "gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is ready"

# Login to GHCR
echo "🐳 Logging into GitHub Container Registry..."
echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin

# Alternative method using GitHub CLI token
gh auth token | docker login ghcr.io -u $(gh api user --jq .login) --password-stdin

echo "✅ Successfully logged into GHCR"
echo ""
echo "🏗️ Now you can build and push images using:"
echo "  ./scripts/build-images.sh"
echo ""
echo "Or build locally first:"
echo "  ./scripts/build-local.sh"
echo "  docker tag cintaraio/cintara-node:latest ghcr.io/cintaraio/cintara-node:latest"
echo "  docker tag cintaraio/cintara-ai-bridge:latest ghcr.io/cintaraio/cintara-ai-bridge:latest"
echo "  docker push ghcr.io/cintaraio/cintara-node:latest"
echo "  docker push ghcr.io/cintaraio/cintara-ai-bridge:latest"