# GraphSense Telestai - Makefile
# Common commands to manage the ecosystem

.PHONY: help build start stop restart logs clean setup init-db ingest status monitor

# Variables
COMPOSE_FILE=docker-compose.yml
SERVICES_CORE=cassandra spark-master spark-worker-1 graphsense-lib graphsense-rest
SERVICES_INFRA=cassandra spark-master spark-worker-1
SERVICES_APP=graphsense-lib graphsense-rest

# Default target
help: ## Show this help
	@echo "GraphSense Telestai - Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Setup and Build
setup: ## Setup project (create .env from example)
	@echo "🔧 Setting up project..."
	@if [ ! -f .env ]; then \
		cp config-vars.env.example .env; \
		echo "✅ .env file created. Edit it with your Telestai configurations."; \
	else \
		echo "⚠️  .env file already exists."; \
	fi

build: ## Build core Docker images (excluding dashboard)
	@echo "🏗️  Building Docker images for core services..."
	docker-compose build $(SERVICES_APP)

# Service Management
start: ## Start all services
	@echo "🚀 Starting infrastructure services..."
	docker-compose up -d $(SERVICES_INFRA)
	@echo "⏳ Waiting for Cassandra to be ready..."
	@sleep 30
	@echo "🚀 Starting application services..."
	docker-compose up -d $(SERVICES_APP)

start-infra: ## Start only infrastructure services (Cassandra, Spark)
	@echo "🚀 Starting infrastructure services..."
	docker-compose up -d $(SERVICES_INFRA)

start-apps: ## Start only application services (GraphSense)
	@echo "🚀 Starting application services..."
	docker-compose up -d $(SERVICES_APP)

stop: ## Stop all services
	@echo "🛑 Stopping all services..."
	docker-compose down

restart: ## Restart all services
	@echo "🔄 Restarting services..."
	$(MAKE) stop
	@sleep 5
	$(MAKE) start

# Database Management
init-db: ## Initialize database schemas for Telestai
	@echo "🗄️  Initializing database for Telestai..."
	@echo "⏳ Waiting for services to be ready..."
	@sleep 10
	docker-compose exec graphsense-lib graphsense-cli --config-file /app/config/config.yaml schema create -e dev -c btc
	@echo "✅ Database schemas created."

test-connection: ## Test GraphSense system status
	@echo "🔍 Testing GraphSense system status..."
	docker-compose exec graphsense-lib graphsense-cli --config-file /app/config/config.yaml monitoring get-summary -e dev -c btc

# Data Ingestion
ingest-batch: ## Batch ingestion of blocks (historical)
	@echo "📥 Starting batch ingestion..."
	docker-compose exec graphsense-lib graphsense-cli --config-file /app/config/config.yaml ingest from-node --env dev --currency btc --batch-size 10 --mode utxo_with_tx_graph --create-schema

ingest-continuous: ## Continuous ingestion (new blocks)
	@echo "📥 Starting continuous ingestion..."
	docker-compose exec graphsense-lib graphsense-cli --config-file /app/config/config.yaml ingest from-node -c telestai --continuous

transform: ## Execute data transformation
	@echo "🔄 Executing data transformation..."
	docker-compose exec graphsense-lib graphsense-cli --config-file /app/config/config.yaml delta-update update --env dev --currency btc

# Monitoring and Logs
logs: ## View logs of all services
	docker-compose logs -f

logs-lib: ## View logs of graphsense-lib
	docker-compose logs -f graphsense-lib

logs-rest: ## View logs of graphsense-rest
	docker-compose logs -f graphsense-rest

logs-cassandra: ## View logs of Cassandra
	docker-compose logs -f cassandra

status: ## Show status of all services
	@echo "📊 Service status:"
	docker-compose ps
	@echo ""
	@echo "📈 Resource usage:"
	docker stats --no-stream

health: ## Verificar salud de servicios
	@echo "🏥 Verificando salud de servicios..."
	@echo "Cassandra:"
	@docker-compose exec cassandra cqlsh -e "SELECT now() FROM system.local;" 2>/dev/null && echo "✅ Cassandra OK" || echo "❌ Cassandra ERROR"
	@echo "REST API:"
	@curl -s http://localhost:9000/health >/dev/null && echo "✅ REST API OK" || echo "❌ REST API ERROR"
	@echo "Dashboard:"
	@curl -s http://localhost:8080 >/dev/null && echo "✅ Dashboard OK" || echo "❌ Dashboard ERROR"

verify: ## Verify installation and system readiness
	@echo "🔍 Running system verification..."
	./verify-installation.sh

# Monitoring
monitor: ## Start services with monitoring (Prometheus + Grafana)
	@echo "📊 Starting services with monitoring..."
	COMPOSE_PROFILES=default,monitoring docker-compose up -d

# Maintenance
clean: ## Clean unused containers, images and volumes
	@echo "🧹 Cleaning Docker resources..."
	docker-compose down -v
	docker system prune -f
	docker volume prune -f

clean-data: ## DANGER: Delete all Cassandra data
	@echo "⚠️  DANGER: This will delete ALL Telestai data!"
	@read -p "Are you sure? Type 'DELETE' to confirm: " confirm; \
	if [ "$$confirm" = "DELETE" ]; then \
		docker-compose exec cassandra cqlsh -e "DROP KEYSPACE IF EXISTS telestai_raw;"; \
		docker-compose exec cassandra cqlsh -e "DROP KEYSPACE IF EXISTS telestai_transformed;"; \
		echo "🗑️  Data deleted."; \
	else \
		echo "❌ Operation cancelled."; \
	fi

# Backup
backup: ## Create Cassandra data backup
	@echo "💾 Creating Cassandra backup..."
	mkdir -p ./backups/$(shell date +%Y%m%d_%H%M%S)
	docker-compose exec cassandra nodetool snapshot telestai_raw
	docker-compose exec cassandra nodetool snapshot telestai_transformed
	@echo "✅ Backup created in Cassandra snapshots."

# Development
dev-setup: setup build init-db ## Complete development setup
	@echo "🎯 Development setup completed."
	@echo "📋 Next steps:"
	@echo "   1. Edit .env with your Telestai node configuration"
	@echo "   2. Run: make start"
	@echo "   3. Run: make test-connection"
	@echo "   4. Run: make ingest-batch"

# Quick commands
quick-start: ## Quick start (build + start + init-db)
	$(MAKE) build
	$(MAKE) start
	@sleep 30
	$(MAKE) init-db

# Access URLs
urls: ## Show service access URLs
	@echo "🌐 Access URLs:"
	@echo "   Dashboard:  http://localhost:8080"
	@echo "   REST API:   http://localhost:9000"
	@echo "   Spark UI:   http://localhost:8080"
	@echo "   Prometheus: http://localhost:9090 (if enabled)"
	@echo "   Grafana:    http://localhost:3000 (if enabled)"