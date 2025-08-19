#!/bin/bash
# Setup script for GraphSense Avian with tree-sitter fix
# This script applies the tree-sitter compilation fix to the dashboard submodule

set -e

echo "🔧 GraphSense Avian Setup with Dashboard Fix"
echo "============================================="

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ] || [ ! -d "graphsense-dashboard" ]; then
    echo "❌ Error: Please run this script from the Avian-Blockchain-Analysis root directory"
    exit 1
fi

# Create docker directory if it doesn't exist
if [ ! -d "docker" ]; then
    echo "📁 Creating docker directory..."
    mkdir -p docker
fi

# Copy fixed Dockerfiles to main project
echo "📋 Copying custom Dockerfiles..."

if [ -f "graphsense-dashboard/Dockerfile.fixed" ]; then
    cp "graphsense-dashboard/Dockerfile.fixed" "docker/graphsense-dashboard-alpine.Dockerfile"
    echo "✅ Dashboard Alpine Dockerfile copied"
elif [ -f "docker/graphsense-dashboard-alpine.Dockerfile" ]; then
    echo "✅ Dashboard Alpine Dockerfile already exists"
else
    echo "⚠️  Warning: graphsense-dashboard/Dockerfile.fixed not found"
fi

if [ -f "graphsense-dashboard/Dockerfile.ubuntu" ]; then
    cp "graphsense-dashboard/Dockerfile.ubuntu" "docker/graphsense-dashboard-ubuntu.Dockerfile"
    echo "✅ Dashboard Ubuntu Dockerfile copied"
elif [ -f "docker/graphsense-dashboard-ubuntu.Dockerfile" ]; then
    echo "✅ Dashboard Ubuntu Dockerfile already exists"
fi

# Check if custom graphsense-lib Dockerfile exists
if [ -f "docker/graphsense-lib.Dockerfile" ]; then
    echo "✅ Custom GraphSense Lib Dockerfile found"
else
    echo "⚠️  Warning: docker/graphsense-lib.Dockerfile not found"
fi

# Update docker-compose.yml if needed
echo "🔧 Checking docker-compose.yml configuration..."

# Only update the graphsense-dashboard service, not all services
if grep -A 5 "graphsense-dashboard:" docker-compose.yml | grep -q "dockerfile: Dockerfile"; then
    echo "🔄 Updating docker-compose.yml to use custom Dockerfiles..."
    sed -i '/graphsense-dashboard:/,/dockerfile: Dockerfile/s|dockerfile: Dockerfile|dockerfile: ../docker/graphsense-dashboard-alpine.Dockerfile|' docker-compose.yml
    echo "✅ Dashboard docker-compose.yml updated"
else
    echo "✅ Dashboard docker-compose.yml already configured"
fi

# Check for graphsense-lib Dockerfile configuration
if grep -q "context: ./graphsense-lib" docker-compose.yml && grep -q "dockerfile: Dockerfile" docker-compose.yml; then
    echo "🔄 Updating graphsense-lib to use custom Dockerfile..."
    sed -i '/context: \.\/graphsense-lib/,/dockerfile: Dockerfile/s|dockerfile: Dockerfile|dockerfile: ../docker/graphsense-lib.Dockerfile|' docker-compose.yml
    echo "✅ GraphSense Lib docker-compose.yml updated"
else
    echo "✅ GraphSense Lib docker-compose.yml already configured"
fi

# Create .env if it doesn't exist
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file..."
    cp config-vars.env.example .env
    echo "✅ .env file created. Please edit it with your Avian configuration."
else
    echo "✅ .env file already exists"
fi

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Edit .env with your Avian node configuration"
echo "   2. Run: make build-all           # Build all services (lib + rest + dashboard)"
echo "   3. Run: make start-with-dashboard # Start all services with dashboard"
echo "   4. Run: make init-db             # Initialize database"
echo ""
echo "🌐 Once running, access:"
echo "   Dashboard:  http://localhost:8081"
echo "   REST API:   http://localhost:9000"
echo ""
echo "ℹ️  Available commands:"
echo "   make build-lib           # Build GraphSense Lib with custom Dockerfile"
echo "   make build-dashboard     # Build dashboard with Alpine-based fix"
echo "   make start-dashboard     # Start only dashboard"
echo "   make help               # Show all available commands"
