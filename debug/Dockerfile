# syntax=docker/dockerfile:1

FROM debian:trixie-slim AS rclone-tool
ARG RCLONE_VERSION=1.75.1
ARG TARGETARCH
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg unzip; \
    rm -rf /var/lib/apt/lists/*; \
    curl -fsSL https://rclone.org/KEYS -o /tmp/rclone-keys; \
    gpg --show-keys --with-colons /tmp/rclone-keys | grep -F 'FBF737ECE9F8AB18604BD2AC93935E02FF3B54FA'; \
    gpg --batch --import /tmp/rclone-keys; \
    case "${TARGETARCH}" in \
        amd64) rclone_arch=amd64 ;; \
        arm64) rclone_arch=arm64 ;; \
        *) echo "unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    rclone_archive="rclone-v${RCLONE_VERSION}-linux-${rclone_arch}.zip"; \
    curl -fsSL "https://downloads.rclone.org/v${RCLONE_VERSION}/SHA256SUMS" -o /tmp/SHA256SUMS; \
    curl -fsSL "https://downloads.rclone.org/v${RCLONE_VERSION}/${rclone_archive}" -o "/tmp/${rclone_archive}"; \
    gpg --batch --verify /tmp/SHA256SUMS; \
    gpg --batch --decrypt /tmp/SHA256SUMS 2>/dev/null | grep "  ${rclone_archive}$" | (cd /tmp && sha256sum -c -); \
    unzip -q "/tmp/${rclone_archive}" -d /tmp/rclone; \
    install -D -m 755 "/tmp/rclone/rclone-v${RCLONE_VERSION}-linux-${rclone_arch}/rclone" /out/rclone; \
    rm -rf /tmp/rclone /tmp/rclone-keys /tmp/SHA256SUMS "/tmp/${rclone_archive}"

FROM debian:trixie-slim AS rsync-tool
ARG RSYNC_VERSION=3.5.1
ARG RSYNC_SHA256=c55f9c9dc10fb8bec397b399a0fdded53cc9a2d8e30891bb0d63724d25c37bef
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl python3 build-essential libacl1-dev libattr1-dev \
        libidn2-dev liblz4-dev libpopt-dev libxxhash-dev libzstd-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
RUN set -eux; \
    curl -fsSL "https://download.samba.org/pub/rsync/src/rsync-${RSYNC_VERSION}.tar.gz" -o /tmp/rsync.tar.gz; \
    echo "${RSYNC_SHA256}  /tmp/rsync.tar.gz" | sha256sum -c -; \
    mkdir /tmp/rsync-src; \
    tar -xzf /tmp/rsync.tar.gz --strip-components=1 -C /tmp/rsync-src; \
    cd /tmp/rsync-src; \
    ./configure --prefix=/usr/local --disable-openssl; \
    make -j2; \
    make install; \
    rm -rf /tmp/rsync-src /tmp/rsync.tar.gz

FROM debian:trixie-slim

LABEL org.opencontainers.image.title="debug" \
      org.opencontainers.image.description="Debian-based image with common cluster debug tools" \
      org.opencontainers.image.source="https://github.com/dacbd/toolboxes"

ENV DEBIAN_FRONTEND=noninteractive

ARG ARGOCD_VERSION=v3.5.3
ARG GH_VERSION=2.101.0
ARG TARGETARCH

# Finish the download/compiler tool stages before the memory-intensive package
# installation in the final image.
COPY --from=rclone-tool /out/rclone /usr/local/bin/rclone
COPY --from=rsync-tool /usr/local/bin/rsync /usr/local/bin/rsync

# system tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        dnsutils \
        fd-find \
        file \
        git \
        git-lfs \
        gzip \
        iproute2 \
        iputils-ping \
        jq \
        less \
        libacl1 \
        libattr1 \
        libpopt0 \
        libxxhash0 \
        libzstd1 \
        liblz4-1 \
        netcat-openbsd \
        openssh-client \
        openssl \
        procps \
        python3 \
        python-is-python3 \
        ripgrep \
        sqlite3 \
        tar \
        tcpdump \
        traceroute \
        tree \
        unzip \
        wget \
        xz-utils \
        zip \
        zstd \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && git lfs install --system \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI from its official release with the published per-architecture checksum.
RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) gh_arch=amd64; gh_sha256=9bca2d1c16825f109907a23307628a2f0698fbf99662b73a5cf0b020293072b8 ;; \
        arm64) gh_arch=arm64; gh_sha256=b57e8063f18862647c9d22727c32e9da1b963f8bf9db648fe123a6975695640f ;; \
        *) echo "unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    gh_archive="gh_${GH_VERSION}_linux_${gh_arch}.tar.gz"; \
    curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/${gh_archive}" -o "/tmp/${gh_archive}"; \
    echo "${gh_sha256}  /tmp/${gh_archive}" | sha256sum -c -; \
    tar -xzf "/tmp/${gh_archive}" -C /tmp; \
    install -m 755 "/tmp/gh_${GH_VERSION}_linux_${gh_arch}/bin/gh" /usr/local/bin/gh; \
    rm -rf "/tmp/${gh_archive}" "/tmp/gh_${GH_VERSION}_linux_${gh_arch}"

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
