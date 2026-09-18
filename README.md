# toolboxes

Small container images for debugging and remote development.

- `debug`: Debian-based Kubernetes/debug pod image with tools like `argocd`, `curl`, `gh`, `jq`, DNS tools, `iproute2`, `ping`, `netcat`, `tcpdump`, and `traceroute`.
- `agents`: Debian-based dev container for remote agent harnesses; includes OpenCode, DeepSeek Harness (`dsh`), common CLI tools, Node, Go, and Rust.

The agents image runs as `agent` (UID/GID `1000`) with home and working
directory `/home/agent`. This directory and the Rust toolchain directories
are writable by this user. Global npm installs and uv tools go
under `~/.local`, whose `bin` directory is on `PATH`.

Python includes `uv`/`uvx`, virtual environment support, development headers,
and the `python` alias. Extra tools include `just`, `git-lfs`, `rsync`,
`rclone`, and `sqlite3`; Git LFS is enabled system-wide.

For host bind mounts, match the host user's IDs at build time with
`--build-arg AGENT_UID=... --build-arg AGENT_GID=...` and ensure the mounted
workspace is writable by those IDs. Mounting a directory replaces its image
ownership; the container does not automatically change host file ownership.
Rust caches and toolchains live at `/usr/local/cargo` and `/usr/local/rustup`.

The entrypoint defaults to `opencode`, which runs
`opencode serve --hostname 0.0.0.0 --port 4096`. Select `dsh` to run
`dsh web --no-open` instead. Arguments after the selector are forwarded to
the selected server; other commands are executed directly.

```sh
docker run --rm -p 127.0.0.1:4096:4096 agents:local opencode
docker run --rm agents:local dsh
docker run --rm -it agents:local bash
```

DeepSeek's Web UI defaults to container loopback on port 3080 and rejects
`--host 0.0.0.0`. Publishing port 3080 alone does not make it reachable;
use a tunnel or proxy that can reach the container's loopback interface.
See the [DeepSeek CLI reference](https://github.com/deepseek-ai/deepseek-harness/blob/master/apps/cli/reference/README.md#web-profile)
for host and trusted-host options. To invoke either CLI without the server
shortcut, override the entrypoint, for example
`docker run --rm --entrypoint dsh agents:local --version`.

Build commands:

```sh
just setup                  # install Trivy if missing
just debug build-local      # local host-architecture image
just debug build            # multi-arch OCI archive: dist/debug.tar
just agents build-local     # local host-architecture image
just agents smoke           # verify tools and non-root development workflows
just agents scan            # scan the local agents image with Trivy
just agents build           # multi-arch OCI archive: dist/agents.tar
```

Security scanning requires [Trivy](https://trivy.dev/docs/latest/getting-started/installation/)
on the host. `just setup` skips installation when Trivy is on `PATH`, otherwise
uses Homebrew on macOS. On Linux it uses APT (Debian/Ubuntu) or DNF/YUM
(RPM-based distributions) with Trivy’s official signed package repository,
using `sudo` unless already running as root. Unsupported package managers
produce an error with a link to manual installation instructions. Run `just agents build-local` before scanning the default
`agents:local` image, or supply a registry image explicitly:

```sh
just agents scan ghcr.io/dacbd/toolboxes/agents:latest
SCAN_SEVERITY=UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL just agents scan
```

The scan checks OS/application vulnerabilities and embedded secrets, prints
the report, and exits nonzero for findings at the selected severities
(`HIGH,CRITICAL` by default), including vulnerabilities without a fix.
Trivy needs registry/database access on the first scan. Scanning is an
explicit recipe for local builds and pushes. CI runs `just setup`, builds and
scans both amd64 and arm64 agent images, and blocks the publishing steps if
either scan fails.
