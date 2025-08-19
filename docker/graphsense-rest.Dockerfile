# Custom GraphSense REST Dockerfile with Cassandra protocol version 4 fix
FROM python:3.11-alpine3.20 AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv
LABEL org.opencontainers.image.title="graphsense-rest"
LABEL org.opencontainers.image.maintainer="contact@ikna.io"
LABEL org.opencontainers.image.url="https://www.ikna.io/"
LABEL org.opencontainers.image.description="Dockerized Graphsense REST interface with protocol v4 fix"
LABEL org.opencontainers.image.source="https://github.com/graphsense/graphsense-REST"

ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV NUM_WORKERS=
ENV NUM_THREADS=
ENV CONFIG_FILE=./instance/config.yaml

# Install system dependencies
RUN apk --no-cache --update add \
    bash \
    shadow \
    git \
    postgresql-dev \
    libevdev-dev \
    musl-dev \
    gcc \
    g++ \
    make

# Copy code
RUN mkdir -p /srv/graphsense-rest/
COPY gsrest /srv/graphsense-rest/gsrest
COPY openapi_server /srv/graphsense-rest/openapi_server
COPY pyproject.toml /srv/graphsense-rest/
COPY uv.lock /srv/graphsense-rest/
COPY README.md /srv/graphsense-rest/

# Apply protocol version fix
RUN sed -i 's/protocol_version=5,/protocol_version=int(self.config.get("protocol_version", 4)),/' /srv/graphsense-rest/gsrest/db/cassandra.py

# Install dependencies
WORKDIR /srv/graphsense-rest
RUN uv sync --frozen

# Create instance directory for config
RUN mkdir -p instance

# Production stage
FROM python:3.11-alpine3.20 AS runner
RUN apk --no-cache --update add \
    bash \
    shadow \
    postgresql-libs

COPY --from=builder /srv/graphsense-rest /srv/graphsense-rest
WORKDIR /srv/graphsense-rest

ENV VIRTUAL_ENV=/srv/graphsense-rest/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Expose port
EXPOSE 9000

# Start the application
CMD ["python", "-m", "gsrest.service"]
