#!/bin/bash

# Generate a secure password for Cintara keyring
# Usage: ./scripts/generate-secure-password.sh

echo "🔐 Generating secure keyring password..."

# Generate a cryptographically secure password
PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-16)

echo "Generated password: $PASSWORD"
echo ""
echo "📝 To use this password:"
echo "1. Add to your .env file:"
echo "   KEYRING_PASSWORD=$PASSWORD"
echo ""
echo "2. Or export as environment variable:"
echo "   export KEYRING_PASSWORD=\"$PASSWORD\""
echo ""
echo "💾 Save this password securely - you'll need it to access your wallet!"
echo "⚠️  Never commit the .env file with real passwords to version control!"