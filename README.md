# toolboxes

Small container images for debugging and remote development.

- `debug`: Debian-based Kubernetes/debug pod image with tools like `argocd`, `curl`, `gh`, `jq`, DNS tools, `iproute2`, `ping`, `netcat`, `tcpdump`, and `traceroute`.
- `agents`: Debian-based dev container for remote agent harnesses; currently runs `opencode serve` and includes common CLI tools plus Node, Go, Rust, and opencode.

The agents image runs as `agent` (UID/GID `1000`) with home `/home/agent`
and working directory `/workspace`. Both directories and the Rust toolchain
directories are writable by this user. Global npm installs and uv tools go
under `~/.local`, whose `bin` directory is on `PATH`.

Python includes `uv`/`uvx`, virtual environment support, development headers,
and the `python` alias. Extra tools include `just`, `git-lfs`, `rsync`,
`rclone`, and `sqlite3`; Git LFS is enabled system-wide.

For host bind mounts, match the host user's IDs at build time with
`--build-arg AGENT_UID=... --build-arg AGENT_GID=...` and ensure the mounted
workspace is writable by those IDs. Mounting a directory replaces its image
ownership; the container does not automatically change host file ownership.
Rust caches and toolchains live at `/usr/local/cargo` and `/usr/local/rustup`.

Build commands:

```sh
just debug build-local      # local host-architecture image
just debug build            # multi-arch OCI archive: dist/debug.tar
just agents build-local     # local host-architecture image
just agents smoke           # verify tools and non-root development workflows
just agents build           # multi-arch OCI archive: dist/agents.tar
```
