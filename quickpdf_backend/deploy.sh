#!/bin/bash

# QuickPDF Production Deployment Script

set -e

echo "🚀 Starting QuickPDF Production Deployment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if .env.production exists
if [ ! -f .env.production ]; then
    echo "❌ .env.production file not found. Please create it first."
    exit 1
fi

# Load production environment variables
export $(cat .env.production | grep -v '^#' | xargs)

echo "📋 Environment: $NODE_ENV"
echo "🗄️  Database: $DB_HOST:$DB_PORT/$DB_NAME"

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose -f docker-compose.prod.yml down

# Build and start services
echo "🔨 Building and starting services..."
docker-compose -f docker-compose.prod.yml up -d --build

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 30

# Check service health
echo "🔍 Checking service health..."
docker-compose -f docker-compose.prod.yml ps

# Run database migrations
echo "📊 Running database migrations..."
docker-compose -f docker-compose.prod.yml exec quickpdf-api node run-migrations.js

# Show logs
echo "📋 Recent logs:"
docker-compose -f docker-compose.prod.yml logs --tail=20 quickpdf-api

echo "✅ Deployment completed successfully!"
echo "🌐 API: http://localhost:3000"
echo "📊 Health: http://localhost:3000/api/v1/health"
echo "📄 Templates: http://localhost:3000/api/v1/templates"

echo ""
echo "📋 Useful commands:"
echo "  View logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "  Stop services: docker-compose -f docker-compose.prod.yml down"
echo "  Restart: docker-compose -f docker-compose.prod.yml restart"