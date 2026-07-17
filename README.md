# toolboxes

Small container images for debugging and remote development.

- `debug`: Debian-based Kubernetes/debug pod image with tools like `argocd`, `curl`, `jq`, DNS tools, `iproute2`, `ping`, `netcat`, `tcpdump`, and `traceroute`.
- `agents`: Debian-based dev container for remote agent harnesses; currently runs `opencode serve` and includes common CLI tools plus Node, Go, Rust, and opencode.

Build commands:

```sh
just debug build-local      # local host-architecture image
just debug build            # multi-arch OCI archive: dist/debug.tar
just agents build-local     # local host-architecture image
just agents build           # multi-arch OCI archive: dist/agents.tar
```
