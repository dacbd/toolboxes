# syntax=docker/dockerfile:1

FROM node:22-bookworm-slim AS node-toolchain
FROM golang:1-bookworm AS go-toolchain
FROM rust:1-bookworm AS rust-toolchain
FROM ghcr.io/astral-sh/uv:0.12.13 AS uv-toolchain

FROM rust-toolchain AS just-builder
ARG JUST_VERSION=1.58.0
RUN cargo install --locked --version "${JUST_VERSION}" --root /opt/just just

FROM debian:bookworm-slim

ARG AGENT_UID=1000
ARG AGENT_GID=1000

RUN groupadd --gid "${AGENT_GID}" agent \
    && useradd --uid "${AGENT_UID}" --gid "${AGENT_GID}" --create-home --shell /bin/bash agent

LABEL org.opencontainers.image.title="agents" \
      org.opencontainers.image.description="Debian-based remote agent development container" \
      org.opencontainers.image.source="https://github.com/dacbd/toolboxes"

ENV DEBIAN_FRONTEND=noninteractive \
    NODE_ENV=development \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    HOME=/home/agent \
    NPM_CONFIG_PREFIX=/home/agent/.local \
    PATH=/home/agent/.local/bin:/usr/local/go/bin:/usr/local/cargo/bin:$PATH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY --from=node-toolchain /usr/local/bin/node /usr/local/bin/node
COPY --from=node-toolchain /usr/local/include/node /usr/local/include/node
COPY --from=node-toolchain /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=go-toolchain /usr/local/go /usr/local/go
COPY --from=rust-toolchain --chown=agent:agent /usr/local/cargo /usr/local/cargo
COPY --from=rust-toolchain --chown=agent:agent /usr/local/rustup /usr/local/rustup
COPY --from=uv-toolchain /uv /uvx /usr/local/bin/
COPY --from=just-builder /opt/just/bin/just /usr/local/bin/just

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
        git-lfs \
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
        python3-dev \
        python3-venv \
        python-is-python3 \
        rclone \
        ripgrep \
        rsync \
        sqlite3 \
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
    && npm install -g --prefix /usr/local opencode-ai@latest \
    && corepack enable \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/local/go/bin/go /usr/local/bin/go \
    && ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt \
    && for tool in cargo cargo-clippy cargo-fmt clippy-driver rust-analyzer rustc rustdoc rustfmt rustup; do \
        ln -sf "/usr/local/cargo/bin/${tool}" "/usr/local/bin/${tool}"; \
    done

RUN mkdir -p /workspace /home/agent/.local/bin /home/agent/.cache \
    && chown -R agent:agent /workspace /home/agent \
    && git lfs install --system

USER agent
WORKDIR /workspace

EXPOSE 4096

CMD ["opencode", "serve", "--hostname", "0.0.0.0", "--port", "4096"]
