# syntax=docker/dockerfile:1

FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="debug" \
      org.opencontainers.image.description="Debian-based image with common cluster debug tools" \
      org.opencontainers.image.source="https://github.com/dacbd/toolboxes"

ENV DEBIAN_FRONTEND=noninteractive

ARG ARGOCD_VERSION=v3.4.4
ARG TARGETARCH

# system tools
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

# install argocd cli
RUN set -eux; \
    arch="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "${arch}" in \
        amd64|arm64) ;; \
        *) echo "unsupported architecture: ${arch}" >&2; exit 1 ;; \
    esac; \
    curl -fsSLO "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-${arch}"; \
    curl -fsSLO "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/cli_checksums.txt"; \
    grep "  argocd-linux-${arch}$" cli_checksums.txt > "argocd-linux-${arch}.sha256"; \
    sha256sum -c "argocd-linux-${arch}.sha256"; \
    install -m 555 "argocd-linux-${arch}" /usr/local/bin/argocd; \
    rm "argocd-linux-${arch}" "argocd-linux-${arch}.sha256" cli_checksums.txt

WORKDIR /work

CMD ["/bin/bash"]
