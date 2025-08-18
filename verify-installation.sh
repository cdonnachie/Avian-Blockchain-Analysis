#!/bin/bash

# GraphSense Avian Installation Verification Script
# This script verifies that all components are working correctly

set -e

echo "🔍 GraphSense Avian Installation Verification"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        return 1
    fi
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "1. Checking prerequisites..."

# Check Docker
if command_exists docker; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | sed 's/,//')
    print_status 0 "Docker installed (${DOCKER_VERSION})"
else
    print_status 1 "Docker not found. Please install Docker."
    exit 1
fi

# Check Docker Compose
if command_exists docker-compose; then
    COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | sed 's/,//')
    print_status 0 "Docker Compose installed (${COMPOSE_VERSION})"
else
    print_status 1 "Docker Compose not found. Please install Docker Compose."
    exit 1
fi

echo ""
echo "2. Checking required files..."

# Check essential files
required_files=(
    "docker-compose.yml"
    "Makefile" 
    "config/graphsense-lib/config.yaml"
    "config/graphsense-rest/config.yaml"
    "graphsense-lib/Dockerfile"
    "config-vars.env.example"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_status 0 "Found $file"
    else
        print_status 1 "Missing $file"
        exit 1
    fi
done

echo ""
echo "3. Checking environment configuration..."

# Check .env file
if [ -f ".env" ]; then
    print_status 0 "Found .env file"
    
    # Check required environment variables
    required_vars=("AVIAN_RPC_HOST" "AVIAN_RPC_PORT" "AVIAN_RPC_USER" "AVIAN_RPC_PASSWORD")
    
    for var in "${required_vars[@]}"; do
        if grep -q "^${var}=" .env; then
            value=$(grep "^${var}=" .env | cut -d'=' -f2)
            if [ -n "$value" ] && [ "$value" != "your_value_here" ] && [ "$value" != "localhost" ]; then
                print_status 0 "$var is configured"
            else
                print_warning "$var needs to be configured in .env"
            fi
        else
            print_warning "$var not found in .env"
        fi
    done
else
    print_warning ".env file not found. Copy from config-vars.env.example and configure."
fi

echo ""
echo "4. Checking Docker services..."

# Check if any services are running
RUNNING_SERVICES=$(docker-compose ps --services --filter "status=running" 2>/dev/null || echo "")

if [ -n "$RUNNING_SERVICES" ]; then
    echo "Running services:"
    echo "$RUNNING_SERVICES" | while read service; do
        print_status 0 "$service is running"
    done
else
    print_warning "No services are currently running. Use 'make start' to start them."
fi

echo ""
echo "5. Checking network connectivity..."

# Test Docker network
if docker network ls | grep -q "graphsense-avian-net"; then
    print_status 0 "GraphSense network exists"
else
    print_warning "GraphSense network not found. Services may not be running."
fi

echo ""
echo "6. Checking data persistence..."

# Check Docker volumes
volumes=("cassandra_data" "spark_data" "graphsense_config")
for volume in "${volumes[@]}"; do
    if docker volume ls | grep -q "$volume"; then
        print_status 0 "Volume $volume exists"
    else
        print_warning "Volume $volume not found. Will be created when services start."
    fi
done

echo ""
echo "7. Testing basic functionality..."

# Test if Cassandra is accessible (if running)
if docker-compose ps cassandra | grep -q "Up"; then
    if docker-compose exec -T cassandra cqlsh -e "DESCRIBE KEYSPACES;" >/dev/null 2>&1; then
        print_status 0 "Cassandra is accessible"
        
        # Check if GraphSense keyspaces exist
        if docker-compose exec -T cassandra cqlsh -e "DESCRIBE KEYSPACES;" | grep -q "btc_raw_dev"; then
            print_status 0 "Raw keyspace exists"
        else
            print_warning "Raw keyspace not found. Run 'make init-db' to create."
        fi
        
        if docker-compose exec -T cassandra cqlsh -e "DESCRIBE KEYSPACES;" | grep -q "btc_transformed_dev"; then
            print_status 0 "Transformed keyspace exists"
        else
            print_warning "Transformed keyspace not found. Run 'make init-db' to create."
        fi
    else
        print_warning "Cassandra is running but not responding to queries."
    fi
else
    print_warning "Cassandra is not running. Use 'make start-infra' to start."
fi

# Test if GraphSense REST API is accessible (if running)
if docker-compose ps graphsense-rest | grep -q "Up"; then
    if curl -s http://localhost:9000 >/dev/null 2>&1; then
        print_status 0 "GraphSense REST API is accessible"
    else
        print_warning "GraphSense REST API is not responding."
    fi
else
    print_warning "GraphSense REST API is not running. Use 'make start-apps' to start."
fi

echo ""
echo "8. System readiness summary..."

# Overall system status
if docker-compose ps | grep -q "Up.*healthy\|Up.*running"; then
    print_status 0 "System has running services"
    echo ""
    echo "🎯 Quick commands to get started:"
    echo "   make start        # Start all services"
    echo "   make init-db      # Initialize database (if not done)"
    echo "   make test-connection  # Test Avian node connection"
    echo "   make logs         # View service logs"
else
    print_warning "System is not fully operational"
    echo ""
    echo "🚀 To start the system:"
    echo "   1. Configure .env file with your Avian node details"
    echo "   2. make start-infra    # Start infrastructure"
    echo "   3. make build          # Build images"  
    echo "   4. make start-apps     # Start applications"
    echo "   5. make init-db        # Initialize database"
fi

echo ""
echo "=============================================="
echo "✨ Verification complete!"
echo ""
echo "📚 For detailed instructions, see README.md"
echo "🔧 For troubleshooting, run: make logs"