#!/bin/bash

# Kali-Headscale Test Script
# Verifies that the Headscale services are working correctly

set -e

echo "🧪 Testing Kali-Headscale setup..."

# Check if services are running
echo "📋 Checking service status..."
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Services are not running. Start with: docker-compose up -d"
    exit 1
fi

echo "✅ Services are running"

# Test Headscale API
echo "🔗 Testing Headscale API..."
if curl -s http://localhost:80/health > /dev/null; then
    echo "✅ Headscale API is responding"
else
    echo "❌ Headscale API is not responding"
fi

# Test Web UI
echo "🌐 Testing Web UI..."
if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ Web UI is responding"
else
    echo "❌ Web UI is not responding"
fi

# Check Headscale CLI
echo "💻 Testing Headscale CLI..."
if docker-compose exec -T headscale headscale version > /dev/null; then
    echo "✅ Headscale CLI is working"
else
    echo "❌ Headscale CLI is not working"
fi

echo ""
echo "🎉 Basic tests completed!"
echo ""
echo "📖 Next steps:"
echo "1. Create a user: docker-compose exec headscale headscale users create testuser"
echo "2. Create an API key: docker-compose exec headscale headscale apikeys create --expiration 90d"
echo "3. Use the API key to authenticate in the web UI at http://localhost:3000"
echo "4. Create a pre-auth key: docker-compose exec headscale headscale preauthkeys create --user testuser --reusable"
echo "5. Register a node: tailscale up --login-server http://localhost:80 --auth-key <preauth-key>"