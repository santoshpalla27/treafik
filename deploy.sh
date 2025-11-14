#!/bin/bash

set -e

echo "🚀 Deploying Traefik + Portainer..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "📝 Please copy .env.example to .env and configure it"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running!"
    exit 1
fi

# Create required directories
mkdir -p traefik landing

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker compose down 2>/dev/null || true

# Remove old volumes (optional - uncomment if needed)
# echo "🗑️  Removing old volumes..."
# docker volume rm traefik_letsencrypt portainer_data 2>/dev/null || true

# Start containers
echo "▶️  Starting containers..."
docker compose up -d

# Wait for containers to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 10

# Check container status
echo ""
echo "📊 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🌐 Access your services:"
echo "   Landing:   https://$(grep ROOT_DOMAIN .env | cut -d '=' -f2)"
echo "   Traefik:   https://$(grep TRAEFIK_DOMAIN .env | cut -d '=' -f2)"
echo "   Portainer: https://$(grep PORTAINER_DOMAIN .env | cut -d '=' -f2)"
echo ""
echo "📝 View logs: docker logs traefik -f"
