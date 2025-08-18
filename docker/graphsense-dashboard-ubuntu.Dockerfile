# Alternative Solution: Ubuntu-based Dockerfile
# Solution 2: Use Ubuntu instead of Alpine for better native compilation support
FROM node:18-bullseye as builder

ENV WORKDIR=/app
WORKDIR $WORKDIR

# Install dependencies (Ubuntu has better support for native modules)
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-setuptools \
    build-essential \
    make \
    g++ \
    git \
    jq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set Python for node-gyp
ENV PYTHON=/usr/bin/python3

# Copy and install dependencies
COPY ./package*.json ./elm-tooling.json ./
RUN npm ci --verbose

# Copy source and build
COPY . .
RUN cp -n ./config/Config.elm.tmp ./config/Config.elm 2>/dev/null || true
RUN touch .env && make build

# Production stage
FROM nginx:alpine
COPY ./docker/site.conf /etc/nginx/http.d/
RUN rm -f /etc/nginx/http.d/default.conf \
    && mkdir -p /usr/share/nginx/html /run/nginx

COPY --from=builder /app/dist /usr/share/nginx/html
COPY ./docker/docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
