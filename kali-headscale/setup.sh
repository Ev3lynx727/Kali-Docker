#!/bin/bash

# Kali-Headscale Setup Script
# This script helps initialize and configure the Headscale services

set -e

echo "🚀 Starting Kali-Headscale setup..."

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose not found. Please install Docker and Docker Compose."
    exit 1
fi

# Start the services
echo "📦 Starting Headscale services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Services failed to start. Check logs with: docker-compose logs"
    exit 1
fi

echo "✅ Services started successfully!"
echo ""
echo "🌐 Access the web UI at: http://localhost:3000"
echo ""
echo "🔑 To create an API key for the web UI:"
echo "   docker-compose exec headscale headscale apikeys create --expiration 90d"
echo ""
echo "👤 To create a user:"
echo "   docker-compose exec headscale headscale users create <username>"
echo ""
echo "🔐 To create a pre-auth key for node registration:"
echo "   docker-compose exec headscale headscale preauthkeys create --user <username> --reusable"
echo ""
echo "📖 See README.md for detailed usage instructions."