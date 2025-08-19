# Fixed Dockerfile for tree-sitter native compilation issues
# Solution 1: Multi-stage build with better dependency management
FROM node:18-alpine as builder
LABEL org.opencontainers.image.title="graphsense-dashboard"
LABEL org.opencontainers.image.maintainer="contact@ikna.io"
LABEL org.opencontainers.image.url="https://www.ikna.io/"
LABEL org.opencontainers.image.description="GraphSense's Web GUI for interactive cryptocurrency analysis written"
LABEL org.opencontainers.image.source="https://github.com/graphsense/graphsense-dashboard"

ENV WORKDIR=/app
WORKDIR $WORKDIR

# Install comprehensive build dependencies for native compilation
RUN apk --no-cache --update add \
    bash \
    python3 \
    py3-pip \
    make \
    g++ \
    gcc \
    musl-dev \
    linux-headers \
    git \
    jq \
    # Additional dependencies for tree-sitter native compilation
    && python3 -m pip install --break-system-packages setuptools wheel

# Set Python path for node-gyp
ENV PYTHON=/usr/bin/python3
ENV npm_config_python=/usr/bin/python3

# Copy package files first for better Docker layer caching
COPY ./package*.json ./
COPY ./elm-tooling.json ./

# Install npm dependencies with specific flags for native compilation
RUN npm ci --verbose \
    # Rebuild tree-sitter specifically
    && npm rebuild @elm-tooling/tree-sitter-elm --verbose

# Copy remaining build files
COPY ./elm.json.base ./index.html ./vite.config.mjs ./Makefile ./
COPY ./config ./config
RUN cp -n ./config/Config.elm.tmp ./config/Config.elm
COPY ./src ./src
COPY ./openapi ./openapi
COPY ./public ./public
COPY ./lang ./lang
COPY ./plugins ./plugins
COPY ./plugin_templates ./plugin_templates
COPY ./themes ./themes
COPY ./theme ./theme
COPY ./codegen ./codegen
COPY ./lib ./lib
COPY ./generate.js ./generate.js
COPY ./tools ./tools

# Build the application
RUN touch .env && make build

# Production stage
FROM nginx:alpine
ENV DOCKER_USER=dockeruser
ENV DOCKER_UID=1000
ENV REST_URL=http://localhost:9000

# Copy nginx configuration
COPY ./docker/site.conf /etc/nginx/http.d/
RUN rm -f /etc/nginx/http.d/default.conf \
    && mkdir -p /usr/share/nginx/html /run/nginx

# Copy built application from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
