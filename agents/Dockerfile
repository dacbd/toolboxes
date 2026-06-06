# syntax=docker/dockerfile:1

FROM node:22-bookworm-slim AS node-toolchain
FROM golang:1-bookworm AS go-toolchain
FROM rust:1-bookworm AS rust-toolchain

FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="agents" \
      org.opencontainers.image.description="Debian-based remote agent development container" \
      org.opencontainers.image.source="https://github.com/dacbd/toolboxes"

ENV DEBIAN_FRONTEND=noninteractive \
    NODE_ENV=development \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/go/bin:/usr/local/cargo/bin:$PATH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY --from=node-toolchain /usr/local/bin/node /usr/local/bin/node
COPY --from=node-toolchain /usr/local/include/node /usr/local/include/node
COPY --from=node-toolchain /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=go-toolchain /usr/local/go /usr/local/go
COPY --from=rust-toolchain /usr/local/cargo /usr/local/cargo
COPY --from=rust-toolchain /usr/local/rustup /usr/local/rustup

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        curl \
        dnsutils \
        fd-find \
        file \
        gh \
        git \
        gzip \
        iproute2 \
        iputils-ping \
        jq \
        less \
        libssl-dev \
        libstdc++6 \
        make \
        netcat-openbsd \
        openssh-client \
        pkg-config \
        procps \
        python3 \
        ripgrep \
        tar \
        tree \
        unzip \
        wget \
        xz-utils \
        zip \
        zstd \
    && ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && ln -sf /usr/local/lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && npm install -g opencode-ai@latest \
    && corepack enable \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/local/go/bin/go /usr/local/bin/go \
    && ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt \
    && for tool in cargo cargo-clippy cargo-fmt clippy-driver rust-analyzer rustc rustdoc rustfmt rustup; do \
        ln -sf "/usr/local/cargo/bin/${tool}" "/usr/local/bin/${tool}"; \
    done

WORKDIR /workspace

EXPOSE 4096

CMD ["opencode", "serve", "--hostname", "0.0.0.0", "--port", "4096"]
