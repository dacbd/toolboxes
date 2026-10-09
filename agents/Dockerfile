# syntax=docker/dockerfile:1

FROM node:22-bookworm-slim AS node-toolchain
FROM golang:1.26.6-bookworm AS go-toolchain
FROM rust:1-bookworm AS rust-toolchain

FROM debian:trixie-slim AS uv-toolchain
ARG UV_VERSION=0.12.13
ARG TARGETARCH
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl tar \
    && rm -rf /var/lib/apt/lists/*
RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) uv_arch=x86_64; uv_sha256=745765a3b6e360ad76743599ae5c42e9278c7edf8bbff9fc76d05bf2623a04dd ;; \
        arm64) uv_arch=aarch64; uv_sha256=2eaa5d94f5db7b3a1a092156b9420459e42ab0217d917fe74a876309cef9b5e9 ;; \
        *) echo "unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    uv_archive="uv-${uv_arch}-unknown-linux-gnu.tar.gz"; \
    curl -fsSL "https://releases.astral.sh/github/uv/releases/download/${UV_VERSION}/${uv_archive}" -o "/tmp/${uv_archive}"; \
    echo "${uv_sha256}  /tmp/${uv_archive}" | sha256sum -c -; \
    mkdir -p /out; \
    tar -xzf "/tmp/${uv_archive}" -C /tmp; \
    install -m 755 "/tmp/uv-${uv_arch}-unknown-linux-gnu/uv" /out/uv; \
    install -m 755 "/tmp/uv-${uv_arch}-unknown-linux-gnu/uvx" /out/uvx; \
    rm -rf "/tmp/${uv_archive}" "/tmp/uv-${uv_arch}-unknown-linux-gnu"

FROM rust-toolchain AS just-builder
ARG JUST_VERSION=1.58.0
RUN cargo install --locked --version "${JUST_VERSION}" --root /opt/just just

# Use the debug base, which already provides curl and CA certificates.
FROM debug-base AS buf-tool
ARG BUF_VERSION=1.73.0
ARG TARGETARCH
RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) buf_arch=x86_64 ;; \
        arm64) buf_arch=aarch64 ;; \
        *) echo "unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/bufbuild/buf/releases/download/v${BUF_VERSION}/buf-Linux-${buf_arch}" -o /usr/local/bin/buf; \
    chmod 755 /usr/local/bin/buf

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
COPY --from=uv-toolchain /out/uv /out/uvx /usr/local/bin/
COPY --from=just-builder /opt/just/bin/just /usr/local/bin/just
COPY --from=buf-tool /usr/local/bin/buf /usr/local/bin/buf

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
    && npm install -g npm@latest \
    && npm install -g --prefix /usr/local @opencode-ai/cli@beta \
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

EXPOSE 4096

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["opencode2"]
