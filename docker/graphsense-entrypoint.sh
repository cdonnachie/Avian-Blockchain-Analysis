#!/bin/bash
# GraphSense Lib Configuration Script
# This script creates the config file with environment variables

set -e

echo "🔧 Configuring GraphSense with environment variables..."

# Default values
AVIAN_RPC_HOST=${AVIAN_RPC_HOST:-"host.docker.internal"}
AVIAN_RPC_PORT=${AVIAN_RPC_PORT:-"7896"}
AVIAN_RPC_USER=${AVIAN_RPC_USER:-"graphsense"}
AVIAN_RPC_PASSWORD=${AVIAN_RPC_PASSWORD:-"secure_password"}

echo "📡 Using Avian node: ${AVIAN_RPC_USER}@${AVIAN_RPC_HOST}:${AVIAN_RPC_PORT}"

# Ensure config directory exists and is writable
mkdir -p /app/config
chmod 755 /app/config

# Create config file with environment variables
cat > /app/config/config.yaml << EOF
# GraphSense configuration for Avian blockchain
# Auto-generated with environment variables

default_environment: dev

environments:
  dev:
    cassandra_nodes: ["cassandra"]
    protocol_version: 4
    username: null
    password: null
    readonly_username: null
    readonly_password: null
    keyspaces:
      # BTC configuration (mapped to Avian)
      btc:
        raw_keyspace_name: "btc_raw_dev"
        transformed_keyspace_name: "btc_transformed_dev"
        schema_type: "utxo"
        disable_delta_updates: false
        ingest_config:
          node_reference: "http://${AVIAN_RPC_USER}:${AVIAN_RPC_PASSWORD}@${AVIAN_RPC_HOST}:${AVIAN_RPC_PORT}"
          secondary_node_references: []
          raw_keyspace_file_sinks: {}
        keyspace_setup_config:
          raw:
            replication_config: "{'class': 'SimpleStrategy', 'replication_factor': 1}"
            data_configuration:
              block_bucket_size: 10000
              tx_bucket_size: 10000
              tx_prefix_length: 4
          transformed:
            replication_config: "{'class': 'SimpleStrategy', 'replication_factor': 1}"
            data_configuration:
              block_bucket_size: 10000
              tx_bucket_size: 10000
              tx_prefix_length: 4

      # Avian configuration
      avian:
        raw_keyspace_name: "avian_raw_dev"
        transformed_keyspace_name: "avian_transformed_dev"
        schema_type: "utxo"
        disable_delta_updates: false
        ingest_config:
          node_reference: "http://${AVIAN_RPC_USER}:${AVIAN_RPC_PASSWORD}@${AVIAN_RPC_HOST}:${AVIAN_RPC_PORT}"
          secondary_node_references: []
          raw_keyspace_file_sinks: {}
        keyspace_setup_config:
          raw:
            replication_config: "{'class': 'SimpleStrategy', 'replication_factor': 1}"
            data_configuration:
              block_bucket_size: 10000
              tx_bucket_size: 10000
              tx_prefix_length: 4
          transformed:
            replication_config: "{'class': 'SimpleStrategy', 'replication_factor': 1}"
            data_configuration:
              block_bucket_size: 10000
              tx_bucket_size: 10000
              tx_prefix_length: 4

# Global settings
slack_topics: {}
cache_directory: "~/.graphsense/cache"
coingecko_api_key: ""
coinmarketcap_api_key: ""
s3_credentials: null
EOF

echo "✅ Configuration created successfully"

# Set proper ownership and switch to dockeruser
chown -R dockeruser:dockeruser /app/config
exec gosu dockeruser "$@"
