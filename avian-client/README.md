# Avian Client Container

This directory contains the Docker configuration for running an Avian blockchain node in a container.

## Features

- **Full Avian Node**: Runs `aviand` with full blockchain synchronization
- **GraphSense Ready**: Configured with all required indexes for GraphSense analysis
- **Health Checks**: Built-in health monitoring
- **ZMQ Support**: Real-time blockchain notifications
- **REST API**: HTTP REST interface for blockchain queries

## Configuration

The Avian node is configured via `docker/avian.conf` with the following key settings:

- **RPC Server**: Enabled on port 7896
- **Indexes**: All required indexes enabled (txindex, addressindex, etc.)
- **ZMQ**: Real-time notifications on ports 28332-28335
- **Network**: Mainnet by default

## Ports

| Port  | Description           |
| ----- | --------------------- |
| 7895  | P2P Network           |
| 7896  | RPC Server            |
| 28332 | ZMQ Raw Blocks        |
| 28333 | ZMQ Raw Transactions  |
| 28334 | ZMQ Hash Transactions |
| 28335 | ZMQ Hash Blocks       |

## Usage

### Start the Avian node:

```bash
docker compose up -d avian-client
```

### Check sync status:

```bash
make avian-sync-status
```

### Get blockchain info:

```bash
make avian-info
```

### Execute custom commands:

```bash
make avian-cli ARGS="getblockcount"
make avian-cli ARGS="getbestblockhash"
```

### View logs:

```bash
make logs-avian
```

## Data Storage

Blockchain data is stored in the `avian_data` Docker volume, which persists between container restarts.

## Initial Sync

The first startup will download the entire Avian blockchain, which may take several hours depending on your connection speed. Monitor progress with:

```bash
make avian-sync-status
```

## Security Notes

- Default RPC credentials: `graphsense` / `secure_password`
- Change credentials in `config/avian/avian.conf` for production
- RPC access is restricted to Docker network by default
