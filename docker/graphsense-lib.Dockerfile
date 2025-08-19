FROM python:3.10-slim AS builder
LABEL org.opencontainers.image.title="graphsense-lib"
LABEL org.opencontainers.image.maintainer="contact@ikna.io"
LABEL org.opencontainers.image.url="https://www.ikna.io/"
LABEL org.opencontainers.image.description="GraphSense core library and CLI tools"
LABEL org.opencontainers.image.source="https://github.com/graphsense/graphsense-lib"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install uv for faster package management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Set environment variables
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV PYTHONPATH=/app
ENV PATH="/app/.venv/bin:$PATH"
ENV SETUPTOOLS_SCM_PRETEND_VERSION=1.0.0

# Copy source code
WORKDIR /app
COPY graphsense-lib/src/ /app/src/
COPY graphsense-lib/pyproject.toml graphsense-lib/uv.lock graphsense-lib/README.md /app/
COPY graphsense-lib/scripts/ /app/scripts/

# Apply protocol version fix for GraphSense Lib
# 1. Add protocol_version field to CassandraConfig
RUN sed -i '/consistency_level: str = Field(/i\    protocol_version: int = Field(\n        default=4, description="Cassandra protocol version"\n    )' /app/src/graphsenselib/config/cassandra_async_config.py \
    # 2. Update the async Cassandra connection to use the config field
    && sed -i 's/protocol_version=5,/protocol_version=int(self.config.protocol_version),/' /app/src/graphsenselib/db/asynchronous/cassandra.py \
    # 3. Fix the synchronous Cassandra connection by uncommenting and setting protocol_version=4
    && sed -i 's/# protocol_version=6,/protocol_version=4,/' /app/src/graphsenselib/db/cassandra.py \
    # 4. Verify the changes
    && grep -n "protocol_version.*Field" /app/src/graphsenselib/config/cassandra_async_config.py || echo "Config field addition failed" \
    && grep -n "protocol_version.*self.config" /app/src/graphsenselib/db/asynchronous/cassandra.py || echo "Async connection update failed" \
    && grep -n "protocol_version=4," /app/src/graphsenselib/db/cassandra.py || echo "Sync connection update failed"

# Install dependencies and build (including ingestion dependencies)
RUN uv sync --frozen --no-dev --extra ingest

FROM python:3.10-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN adduser --system --uid 10000 --group dockeruser

# Copy built application
COPY --from=builder --chown=dockeruser:dockeruser /app /app

# Copy entrypoint script
COPY --chown=root:root docker/graphsense-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/graphsense-entrypoint.sh

# Set environment variables
ENV PYTHONPATH=/app
ENV PATH="/app/.venv/bin:$PATH"
ENV GRAPHSENSE_CONFIG_FILE=/app/config/config.yaml

WORKDIR /app

# Create config directory
RUN mkdir -p /app/config

# Expose volume for configuration
VOLUME ["/app/config", "/app/data"]

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/graphsense-entrypoint.sh"]

# Default command
CMD ["python", "-m", "graphsenselib.cli", "--help"]