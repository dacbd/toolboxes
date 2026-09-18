# syntax=docker/dockerfile:1

FROM node:22-bookworm-slim AS node-toolchain
FROM golang:1-bookworm AS go-toolchain
FROM rust:1-bookworm AS rust-toolchain
FROM ghcr.io/astral-sh/uv:0.12.13 AS uv-toolchain

FROM rust-toolchain AS just-builder
ARG JUST_VERSION=1.58.0
RUN cargo install --locked --version "${JUST_VERSION}" --root /opt/just just

# Supplied by the debug target in docker-bake.hcl.
FROM debug-base

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
        build-essential \
        libssl-dev \
        libstdc++6 \
        pkg-config \
        python3-dev \
        python3-venv \
    && ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && ln -sf /usr/local/lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack \
    && npm install -g --prefix /usr/local opencode-ai@latest @deepseek-ai/dsh@latest \
    && corepack enable \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/local/go/bin/go /usr/local/bin/go \
    && ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt \
    && for tool in cargo cargo-clippy cargo-fmt clippy-driver rust-analyzer rustc rustdoc rustfmt rustup; do \
        ln -sf "/usr/local/cargo/bin/${tool}" "/usr/local/bin/${tool}"; \
    done

RUN mkdir -p /home/agent/.local/bin /home/agent/.cache \
    && chown -R agent:agent /home/agent

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

USER agent
WORKDIR /home/agent

EXPOSE 3080 4096

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["opencode"]
