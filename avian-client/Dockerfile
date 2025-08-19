FROM ubuntu:24.04 as builder
LABEL org.opencontainers.image.title="avian-client"
LABEL org.opencontainers.image.maintainer="GraphSense Team"
LABEL org.opencontainers.image.description="Dockerized Avian blockchain client"
LABEL org.opencontainers.image.source="https://github.com/AvianNetwork/Avian"

ARG AVIAN_VERSION=4.1.0

ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        apt-transport-https \
        ca-certificates \
        wget \
        unzip \
        && \
    cd /tmp && \
    wget https://github.com/AvianNetwork/Avian/releases/download/v${AVIAN_VERSION}/avian-${AVIAN_VERSION}-linux.zip && \
    unzip avian-${AVIAN_VERSION}-linux.zip && \
    install -m 0755 -o root -g root -t /usr/local/bin avian-cli aviand avian-qt

FROM ubuntu:24.04

ARG UID=10000

COPY --from=builder /usr/local/bin/avian* /usr/local/bin/
ADD docker/avian.conf /opt/avian/avian.conf

RUN apt-get update && \
    apt-get install --no-install-recommends -y wget ca-certificates curl && \
    useradd -m -u $UID dockeruser && \
    mkdir -p /opt/avian/data && \
    chown dockeruser -R /opt/avian && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER dockeruser
EXPOSE 7895 7896 8766 18766
WORKDIR /opt/avian

# Health check to verify aviand is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD avian-cli -conf=/opt/avian/avian.conf -datadir=/opt/avian/data getblockchaininfo || exit 1

CMD ["aviand", "-conf=/opt/avian/avian.conf", "-datadir=/opt/avian/data", "-printtoconsole"]
