# syntax=docker/dockerfile:1

FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="debug" \
      org.opencontainers.image.description="Debian-based image with common cluster debug tools" \
      org.opencontainers.image.source="https://github.com/dacbd/toolboxes"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dnsutils \
        iproute2 \
        iputils-ping \
        jq \
        netcat-openbsd \
        openssl \
        procps \
        tcpdump \
        traceroute \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

CMD ["/bin/bash"]
