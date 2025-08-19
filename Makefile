# GraphSense Avian - Makefile
# Common commands to manage the ecosystem

.PHONY: help build start stop restart logs clean setup init-db ingest status monitor

# Variables
COMPOSE_FILE=docker-compose.yml
SERVICES_CORE=cassandra spark-master spark-worker-1 graphsense-lib graphsense-rest
SERVICES_INFRA=cassandra spark-master spark-worker-1 avian-client
SERVICES_APP=graphsense-lib graphsense-rest
SERVICES_ALL=$(SERVICES_APP) graphsense-dashboard

# Default target
help: ## Show this help
	@echo "GraphSense Avian - Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Setup and Build
setup: ## Setup project (create .env from example)
	@echo "🔧 Setting up project..."
	@if [ ! -f .env ]; then \
		cp config-vars.env.example .env; \
		echo "✅ .env file created. Edit it with your Avian configurations."; \
	else \
		echo "⚠️  .env file already exists."; \
	fi

build: ## Build core Docker images (including lib and rest)
	@echo "🏗️  Building Docker images for core services..."
	docker compose build $(SERVICES_APP)

build-infra: ## Build infrastructure Docker images
	@echo "🏗️  Building Docker images for infrastructure services..."
	docker compose build avian-client

build-dashboard: ## Build GraphSense Dashboard with tree-sitter fix (Alpine)
	@echo "🏗️  Building GraphSense Dashboard with Alpine-based tree-sitter fix..."
	docker compose build graphsense-dashboard

build-dashboard-ubuntu: ## Build GraphSense Dashboard with Ubuntu base (alternative)
	@echo "🏗️  Building GraphSense Dashboard with Ubuntu base..."
	docker compose build graphsense-dashboard --build-arg DOCKERFILE=../docker/graphsense-dashboard-ubuntu.Dockerfile

build-lib: ## Build GraphSense Lib with custom Dockerfile
	@echo "🏗️  Building GraphSense Lib..."
	docker compose build graphsense-lib

build-avian: ## Build Avian client Docker image
	@echo "🏗️  Building Avian client..."
	docker compose build avian-client

build-all: build build-lib build-avian build-dashboard ## Build all services including dashboard

# Service Management
start: ## Start all services
	@echo "🚀 Starting infrastructure services..."
	docker compose up -d $(SERVICES_INFRA)
	@echo "⏳ Waiting for Cassandra to be ready..."
	@sleep 30
	@echo "🚀 Starting application services..."
	docker compose up -d $(SERVICES_APP)

start-infra: ## Start only infrastructure services (Cassandra, Spark)
	@echo "🚀 Starting infrastructure services..."
	docker compose up -d $(SERVICES_INFRA)

start-apps: ## Start only application services (GraphSense)
	@echo "🚀 Starting application services..."
	docker compose up -d $(SERVICES_APP)

start-dashboard: ## Start only the dashboard
	@echo "🚀 Starting GraphSense Dashboard..."
	docker compose up -d graphsense-dashboard

start-with-dashboard: ## Start all services including dashboard
	@echo "🚀 Starting infrastructure services..."
	docker compose up -d $(SERVICES_INFRA)
	@echo "⏳ Waiting for Cassandra to be ready..."
	@sleep 30
	@echo "🚀 Starting application services..."
	docker compose up -d $(SERVICES_APP)
	@echo "🎨 Starting dashboard..."
	docker compose up -d graphsense-dashboard

stop: ## Stop all services
	@echo "🛑 Stopping all services..."
	docker compose down

restart: ## Restart all services
	@echo "🔄 Restarting services..."
	$(MAKE) stop
	@sleep 5
	$(MAKE) start

# Database Management
init-db: ## Initialize database schemas for Avian
	@echo "🗄️  Initializing database for Avian..."
	@echo "⏳ Waiting for services to be ready..."
	@echo "🔍 Checking Cassandra health..."
	@timeout=300; \
	while [ $$timeout -gt 0 ]; do \
		if docker compose exec cassandra cqlsh -e "SELECT now() FROM system.local;" >/dev/null 2>&1; then \
			echo "✅ Cassandra is ready!"; \
			break; \
		fi; \
		echo "⏳ Cassandra not ready yet, waiting... ($$timeout seconds remaining)"; \
		sleep 10; \
		timeout=$$((timeout-10)); \
	done; \
	if [ $$timeout -le 0 ]; then \
		echo "❌ Cassandra failed to become ready within 5 minutes"; \
		exit 1; \
	fi
	@echo "🗄️  Creating database schemas..."
	docker compose exec graphsense-lib graphsense-cli --config-file /app/config/config.yaml schema create -e dev -c btc
	@echo "✅ Database schemas created."

test-connection: ## Test GraphSense system status
	@echo "🔍 Testing GraphSense system status..."
	@echo "⏳ Ensuring services are ready..."
	@if ! docker compose exec cassandra cqlsh -e "SELECT now() FROM system.local;" >/dev/null 2>&1; then \
		echo "❌ Cassandra is not ready. Please run 'make start' first."; \
		exit 1; \
	fi
	docker compose exec graphsense-lib graphsense-cli --config-file /app/config/config.yaml monitoring get-summary -e dev -c btc

# Data Ingestion
ingest-batch: ## Batch ingestion of blocks (historical)
	@echo "📥 Starting batch ingestion..."
	docker compose exec graphsense-lib graphsense-cli --config-file /app/config/config.yaml ingest from-node --env dev --currency btc --batch-size 10 --mode utxo_with_tx_graph --create-schema

ingest-continuous: ## Continuous ingestion (new blocks)
	@echo "📥 Starting continuous ingestion..."
	docker compose exec graphsense-lib graphsense-cli --config-file /app/config/config.yaml ingest from-node -c avian --continuous

transform: ## Execute data transformation
	@echo "🔄 Executing data transformation..."
	docker compose exec graphsense-lib graphsense-cli --config-file /app/config/config.yaml delta-update update --env dev --currency btc

# Monitoring and Logs
logs: ## View logs of all services
	docker compose logs -f

logs-lib: ## View logs of graphsense-lib
	docker compose logs -f graphsense-lib

logs-rest: ## View logs of graphsense-rest
	docker compose logs -f graphsense-rest

logs-dashboard: ## View logs of graphsense-dashboard
	docker compose logs -f graphsense-dashboard

logs-cassandra: ## View logs of Cassandra
	docker compose logs -f cassandra

logs-spark: ## View logs of Spark services
	docker compose logs -f spark-master spark-worker-1

logs-spark-master: ## View logs of Spark master
	docker compose logs -f spark-master

logs-spark-worker: ## View logs of Spark worker
	docker compose logs -f spark-worker-1

logs-avian: ## View logs of Avian client
	docker compose logs -f avian-client

status: ## Show status of all services
	@echo "📊 Service status:"
	docker compose ps
	@echo ""
	@echo "📈 Resource usage:"
	docker stats --no-stream

health: ## Verificar salud de servicios
	@echo "🏥 Verificando salud de servicios..."
	@echo "Cassandra:"
	@docker compose exec cassandra cqlsh -e "SELECT now() FROM system.local;" 2>/dev/null && echo "✅ Cassandra OK" || echo "❌ Cassandra ERROR"
	@echo "Avian Node:"
	@docker compose exec avian-client avian-cli -conf=/opt/avian/avian.conf -datadir=/opt/avian/data getblockchaininfo 2>/dev/null && echo "✅ Avian Node OK" || echo "❌ Avian Node ERROR"
	@echo "REST API:"
	@curl -s http://localhost:9000/health >/dev/null && echo "✅ REST API OK" || echo "❌ REST API ERROR"
	@echo "Dashboard:"
	@curl -s http://localhost:8081 >/dev/null && echo "✅ Dashboard OK" || echo "❌ Dashboard ERROR"

verify: ## Verify installation and system readiness
	@echo "🔍 Running system verification..."
	./verify-installation.sh

# Monitoring
monitor: ## Start services with monitoring (Prometheus + Grafana)
	@echo "📊 Starting services with monitoring..."
	COMPOSE_PROFILES=default,monitoring docker compose up -d

# Maintenance
clean: ## Clean unused containers, images and volumes
	@echo "🧹 Cleaning Docker resources..."
	docker compose down -v
	docker system prune -f
	docker volume prune -f

clean-data: ## DANGER: Delete all Cassandra data
	@echo "⚠️  DANGER: This will delete ALL Avian data!"
	@read -p "Are you sure? Type 'DELETE' to confirm: " confirm; \
	if [ "$$confirm" = "DELETE" ]; then \
		docker compose exec cassandra cqlsh -e "DROP KEYSPACE IF EXISTS avian_raw;"; \
		docker compose exec cassandra cqlsh -e "DROP KEYSPACE IF EXISTS avian_transformed;"; \
		echo "🗑️  Data deleted."; \
	else \
		echo "❌ Operation cancelled."; \
	fi

# Backup
backup: ## Create Cassandra data backup
	@echo "💾 Creating Cassandra backup..."
	mkdir -p ./backups/$(shell date +%Y%m%d_%H%M%S)
	docker compose exec cassandra nodetool snapshot avian_raw
	docker compose exec cassandra nodetool snapshot avian_transformed
	@echo "✅ Backup created in Cassandra snapshots."

# Development
dev-setup: setup build-all init-db ## Complete development setup
	@echo "🎯 Development setup completed."
	@echo "📋 Next steps:"
	@echo "   1. Edit .env with your Avian node configuration"
	@echo "   2. Run: make start"
	@echo "   3. Run: make test-connection"
	@echo "   4. Run: make ingest-batch"

# Quick commands
quick-start: ## Quick start (build + start + init-db)
	$(MAKE) build-all
	$(MAKE) start
	$(MAKE) wait-for-services
	$(MAKE) init-db

# Access URLs
urls: ## Show service access URLs
	@echo "🌐 Access URLs:"
	@echo "   Dashboard:  http://localhost:8081"
	@echo "   REST API:   http://localhost:9000"
	@echo "   Spark UI:   http://localhost:8080"
	@echo "   Avian RPC:  http://localhost:7896"
	@echo "   Prometheus: http://localhost:9090 (if enabled)"
	@echo "   Grafana:    http://localhost:3000 (if enabled)"

# Avian Management
avian-info: ## Get Avian blockchain info
	@echo "📊 Avian blockchain information:"
	docker compose exec avian-client avian-cli -conf=/opt/avian/avian.conf -datadir=/opt/avian/data getblockchaininfo

avian-cli: ## Interactive Avian CLI (usage: make avian-cli ARGS="getblockcount")
	docker compose exec avian-client avian-cli -conf=/opt/avian/avian.conf -datadir=/opt/avian/data $(ARGS)

avian-sync-status: ## Check Avian sync status
	@echo "🔄 Avian synchronization status:"
	@docker compose exec avian-client avian-cli -conf=/opt/avian/avian.conf -datadir=/opt/avian/data getblockchaininfo | grep -E "(blocks|headers|verificationprogress)"

wait-for-services: ## Wait for all services to be ready
	@echo "⏳ Waiting for all services to be ready..."
	@echo "🔍 Checking Cassandra..."
	@timeout=300; \
	while [ $$timeout -gt 0 ]; do \
		if docker compose exec cassandra cqlsh -e "SELECT now() FROM system.local;" >/dev/null 2>&1; then \
			echo "✅ Cassandra is ready!"; \
			break; \
		fi; \
		echo "⏳ Cassandra not ready, waiting... ($$timeout seconds remaining)"; \
		sleep 10; \
		timeout=$$((timeout-10)); \
	done; \
	if [ $$timeout -le 0 ]; then \
		echo "❌ Cassandra failed to become ready"; \
		exit 1; \
	fi
	@echo "🔍 Checking Avian client..."
	@timeout=300; \
	while [ $$timeout -gt 0 ]; do \
		if docker compose exec avian-client avian-cli -conf=/opt/avian/avian.conf -datadir=/opt/avian/data getblockchaininfo >/dev/null 2>&1; then \
			echo "✅ Avian client is ready!"; \
			break; \
		fi; \
		echo "⏳ Avian client not ready, waiting... ($$timeout seconds remaining)"; \
		sleep 15; \
		timeout=$$((timeout-15)); \
	done; \
	if [ $$timeout -le 0 ]; then \
		echo "❌ Avian client failed to become ready"; \
		exit 1; \
	fi
	@echo "✅ All services are ready!"

# Diagnostic Commands
diagnose: ## Run system diagnostics
	@echo "🔍 Running system diagnostics..."
	@echo "📊 Service status:"
	@docker compose ps
	@echo ""
	@echo "🌐 Network connectivity tests:"
	@echo "  Testing Cassandra connection from graphsense-lib:"
	@docker compose exec graphsense-lib ping -c 2 cassandra || echo "❌ Cannot reach Cassandra"
	@echo "  Testing Avian connection from graphsense-lib:"
	@docker compose exec graphsense-lib ping -c 2 avian-client || echo "❌ Cannot reach Avian client"
	@echo ""
	@echo "🔌 Port checks:"
	@echo "  Cassandra port 9042:"
	@docker compose exec graphsense-lib nc -zv cassandra 9042 || echo "❌ Port 9042 not accessible"
	@echo "  Avian RPC port 7896:"
	@docker compose exec graphsense-lib nc -zv avian-client 7896 || echo "❌ Port 7896 not accessible"

# Dashboard Management
dashboard-help: ## Show dashboard-specific commands
	@echo "🎨 Dashboard Commands:"
	@echo "   make build-lib               - Build GraphSense Lib with custom Dockerfile"
	@echo "   make build-dashboard         - Build dashboard with Alpine-based fix"
	@echo "   make build-dashboard-ubuntu  - Build dashboard with Ubuntu base (alternative)"
	@echo "   make build-all               - Build all services (lib + rest + dashboard)"
	@echo "   make start-dashboard         - Start only dashboard service"
	@echo "   make start-with-dashboard    - Start all services including dashboard"
	@echo "   make logs-lib                - View graphsense-lib logs"
	@echo "   make logs-dashboard          - View dashboard logs"
	@echo ""
	@echo "📋 Setup:"
	@echo "   ./setup-dashboard-fix.sh     - Apply tree-sitter fix (run once)"
	@echo ""
	@echo "📚 Documentation:"
	@echo "   DASHBOARD_INTEGRATION.md     - Complete integration guide"
	@echo "   DASHBOARD_ALTERNATIVES.md    - Alternative access methods"