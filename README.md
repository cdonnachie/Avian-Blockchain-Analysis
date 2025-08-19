# GraphSense Avian Blockchain Analysis

Complete GraphSense ecosystem for analyzing Avian blockchain, specifically designed for peel chain transaction analysis.

## 🎯 Features

- **Complete UTXO blockchain analysis** - Raw data ingestion and transformed analytics
- **Peel chain detection** - Track sequential transaction patterns and fund movements
- **Address clustering** - Identify related addresses and transaction flows
- **Web Dashboard** - Interactive GraphSense dashboard with tree-sitter fix (✅ **FIXED**)
- **REST API** - GraphSense REST API for programmatic access (✅ **WORKING**)
- **TagStore integration** - PostgreSQL-based taxonomy and labeling system
- **Scalable architecture** - Apache Spark + Cassandra for big data processing
- **Docker-based** - Easy deployment and portability

## 🛠️ Prerequisites

- Docker (20.10+)
- Docker Compose (2.0+)
- Avian node running with RPC enabled
- Minimum 8GB RAM, 4 CPU cores recommended
- 50GB+ free disk space for blockchain data

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo>
cd Avian-Blockchain-Analysis

# Initialize submodules
git submodule update --init --recursive

# Make scripts executable (may be needed after cloning)
chmod +x setup-dashboard-fix.sh verify-installation.sh

# Apply dashboard tree-sitter fix (automated)
./setup-dashboard-fix.sh
```

### 2. Configure Environment

```bash
# Copy environment template
cp config-vars.env.example .env

# Edit with your Avian node details
nano .env
```

**Required environment variables:**

```bash
AVIAN_RPC_HOST=your.avian.node.ip
AVIAN_RPC_PORT=7896
AVIAN_RPC_USER=your_rpc_username
AVIAN_RPC_PASSWORD=your_rpc_password
```

### 3. Start Infrastructure

```bash
# Start Cassandra and Spark
make start-infra

# Wait for services to be ready (30-60 seconds)
make logs
```

### 4. Build and Start GraphSense

```bash
# Build application images
make build

# Start GraphSense services
make start-apps
```

### 5. Initialize Database

```bash
# Create database schemas
make init-db

# Test connection to your Avian node
make test-connection
```

## 📊 Data Ingestion

### Historical Data Import

```bash
# Import blocks from your Avian node
make ingest-batch
```

### Real-time Monitoring

```bash
# Continuous ingestion of new blocks
make ingest-continuous
```

### Data Transformation

```bash
# Process raw data for analytics
make transform
```

## 🔍 Peel Chain Analysis

The system creates specialized tables for peel chain analysis:

### Address Analysis

- **address** - Address statistics and balances
- **address_transactions** - All transactions per address
- **address_incoming_relations** - Incoming transaction flows
- **address_outgoing_relations** - Outgoing transaction flows

### Cluster Analysis

- **cluster** - Address clusters (related addresses)
- **cluster_addresses** - Addresses within each cluster
- **cluster_transactions** - Transactions involving clusters
- **cluster_incoming_relations** - Cluster-level incoming flows
- **cluster_outgoing_relations** - Cluster-level outgoing flows

## 🌐 API Access

GraphSense REST API is available at:

```
http://localhost:9000
```

Example queries:

```bash
# Get address information
curl http://localhost:9000/btc/addresses/your_avian_address

# Get address transactions
curl http://localhost:9000/btc/addresses/your_avian_address/transactions

# Get address neighbors (for peel chain analysis)
curl http://localhost:9000/btc/addresses/your_avian_address/neighbors
```

## 📋 Available Commands

```bash
make help                 # Show all available commands
make start               # Start all services
make stop                # Stop all services
make restart             # Restart all services
make build               # Build Docker images
make init-db             # Initialize database
make test-connection     # Test Avian node connection
make ingest-batch        # Import historical blocks
make ingest-continuous   # Start continuous ingestion
make transform           # Process data for analytics
make logs               # View service logs
make status             # Check service status
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐     ┌─────────────────┐
│   Avian         │───▶│  GraphSense-Lib  │───▶│   Cassandra     │
│   Node (RPC)    │    │  (Data Ingestion)│     │  (Raw Data)     │
└─────────────────┘    └─────────┬────────┘     └────────┬────────┘
                                 │                       │
                                 ▼                       │
                       ┌──────────────────┐              │
                       │  Apache Spark    │◀────────────┘
                       │  (Processing)    │
                       └─────────┬────────┘
                                 │
                                 ▼
┌─────────────────┐    ┌─────────────────┐     ┌──────────────────┐
│   PostgreSQL    │───▶│   Cassandra     │───▶│  GraphSense-REST │
│   (TagStore)    │    │ (Transformed)   │     │   (API)          │
└─────────────────┘    └─────────────────┘     └─────────┬────────┘
                                                         │
                                                         ▼
                                              ┌──────────────────┐
                                              │ GraphSense       │
                                              │ Dashboard        │
                                              │ Port 8081        │
                                              └──────────────────┘
```

## 🔧 Configuration

### Avian Chain Parameters

The system is pre-configured with Avian-specific parameters:

- **Genesis Hash**: `00000056b9854abf830236d77443a8e3556f0244265e3eb12281a7bc43b7ff57`
- **RPC Port**: 7896
- **P2PKH Version**: 60
- **P2SH Version**: 122
- **Schema Type**: UTXO (compatible with Bitcoin/Ravencoin)

### Customization

Edit configuration files for advanced settings:

**GraphSense Core** (`config/graphsense-lib/config.yaml`):

- Database replication settings
- Batch processing parameters
- Spark cluster configuration

**REST API** (`config/graphsense-rest/config.yaml`):

- Cassandra protocol version (default: 4)
- Currency definitions and keyspace mappings
- TagStore connection settings

**TagStore Database**:

- PostgreSQL service for taxonomy and labeling
- Automatically configured with basic schema
- Extensible for custom labels and classifications

## ✅ System Status & Recent Fixes

### Current Working Components

- ✅ **Cassandra Database** - Raw and transformed keyspaces initialized
- ✅ **Apache Spark** - Cluster running and processing ready
- ✅ **GraphSense-REST API** - Responding on port 9000
- ✅ **TagStore Database** - PostgreSQL with taxonomy tables
- ✅ **Configuration Tables** - Basic bootstrap data populated

### Recent Compatibility Fixes

- **Python 3.10 Compatibility** - Fixed `getargspec` import issues in graphsense-lib
- **Cassandra Protocol Version** - Configured protocol v4 for Cassandra 3.11 compatibility
- **REST API Configuration** - Restructured config format for proper currency/keyspace detection
- **TagStore Integration** - Added PostgreSQL service with required taxonomy schema

### API Status Test

```bash
curl http://localhost:9000/health
# Should return JSON response (404 is expected without blockchain data)
```

## 🚨 Troubleshooting

### Common Issues

**Service not starting:**

```bash
docker compose logs service-name
```

**Database connection issues:**

```bash
make test-connection
docker compose exec cassandra cqlsh -e "DESCRIBE KEYSPACES;"
```

**Avian node connection:**

- Verify RPC credentials in `.env`
- Ensure Avian node is running and accessible
- Check firewall/network settings

**Cassandra protocol version error:**
If you encounter "Beta version of protocol used (5/v5-beta)" error:

- This is automatically handled by the current configuration
- Protocol version is set to 4 for Cassandra 3.11 compatibility
- Check `config/graphsense-rest/config.yaml` has `protocol_version: 4`

## 📈 Monitoring

Optional monitoring with Prometheus + Grafana:

```bash
# Start with monitoring
docker compose --profile monitoring up -d

# Access Grafana at http://localhost:3000
# Default: admin/admin
```

## 🎯 System Status & Recent Fixes

### ✅ **Fully Operational System**

The GraphSense Avian system is **completely functional** and ready for blockchain analysis:

- **✅ 382,810+ blocks ingested** (74% of Avian blockchain)
- **✅ 470,205+ transactions processed**
- **✅ Data transformation working** (blocks 1-10,000+ processed)
- **✅ REST API operational** at `http://localhost:9000`
- **✅ TagStore integration** (PostgreSQL taxonomy system)
- **✅ Avian asset support** (new_asset, transfer_asset, reissue_asset)

### 🔧 **Recent Technical Improvements**

- **Python 3.10 compatibility** - Fixed `getargspec` import errors
- **Cassandra protocol v4** - Resolved protocol v5-beta compatibility issues
- **Docker networking** - Proper host.docker.internal configuration
- **Ingestion dependencies** - Full blockchain-etl and btcpy integration
- **TagStore setup** - Complete PostgreSQL integration with country/concept tables

### 🏗️ **Architecture Overview**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Avian         │    │   GraphSense    │    │   Analytics     │
│   Node (RPC)    │◄──►│   Processing    │◄──►│   & REST API    │
│   Port 7896     │    │   (Spark+Cass)  │    │   Port 9000     │
└─────────────────┘    └─────────────────┘    └─────────┬───────┘
                                                        │
                                                        ▼
                                              ┌─────────────────┐
                                              │   TagStore      │
                                              │   PostgreSQL    │
                                              │   Port 5432     │
                                              └─────────────────┘
                                                        │
                                                        ▼
                                              ┌─────────────────┐
                                              │ GraphSense      │
                                              │ Dashboard       │
                                              │ Port 8081       │
                                              └─────────────────┘
```

## 💾 Data Persistence

All data is persisted in Docker volumes:

- `cassandra_data` - Database storage (382k+ blocks, 470k+ transactions)
- `spark_data` - Spark processing data
- `graphsense_config` - Configuration files
- `tagstore_data` - PostgreSQL taxonomy and labeling data

## 🔒 Security Notes

- Change default passwords in production
- Use firewall rules to restrict access
- Keep RPC credentials secure in `.env`
- The `.env` file is excluded from git for security

## 📚 Documentation

- [GraphSense Documentation](https://graphsense.github.io/)
- [Avian Project](https://github.com/Avian-Project/avian)
- [Apache Cassandra](https://cassandra.apache.org/doc/)
- [Apache Spark](https://spark.apache.org/docs/)

## 🤝 Support

For issues specific to this Avian implementation, check:

1. Service logs: `make logs`
2. Connection tests: `make test-connection`
3. Database status: `docker compose exec cassandra cqlsh -e "DESCRIBE KEYSPACES;"`

---

**Ready for Avian peel chain analysis!** 🎯
