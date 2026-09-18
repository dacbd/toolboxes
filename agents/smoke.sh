#!/usr/bin/env bash
set -euo pipefail

test "$(id -un)" = agent
test "$(id -u)" -ne 0
test "$HOME" = /home/agent
for dir in "$HOME" "$CARGO_HOME" "$RUSTUP_HOME"; do
    test -w "$dir"
done
for tool in opencode dsh node npm npx corepack go rustc cargo git git-lfs gh curl jq rg fd python python3 uv uvx just rsync rclone sqlite3; do
    command -v "$tool" >/dev/null || { echo "missing $tool"; exit 1; }
done
opencode --version
dsh --version
dsh web --help
node --version
npm --version
go version
rustc --version
cargo --version
uv --version
just --version
git lfs version
rclone version
rsync --version
test "$(sqlite3 :memory: 'select 1;')" = 1

scratch=$(mktemp -d "$HOME/smoke.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
cd "$scratch"

# Exercise package installation without depending on registry access.
mkdir node-package
echo '{"name":"agent-smoke","version":"1.0.0","bin":{"agent-smoke":"cli.js"}}' > node-package/package.json
printf '#!/usr/bin/env node\nconsole.log("ok");\n' > node-package/cli.js
chmod +x node-package/cli.js
npm install --global --offline --ignore-scripts --no-audit --no-fund ./node-package
test "$(agent-smoke)" = ok
npm uninstall --global --ignore-scripts --no-audit --no-fund agent-smoke

python -m venv python-env
python-env/bin/python -m pip --version
uv venv --offline --python /usr/bin/python3 uv-env
uv-env/bin/python -c 'import ssl, sqlite3'
printf '#include <Python.h>\n' | cc -x c -fsyntax-only $(python3-config --includes) -

printf 'package main\nfunc main() {}\n' > main.go
go build -o go-smoke main.go
./go-smoke
cargo new --quiet --vcs none rust-smoke
cargo build --offline --manifest-path rust-smoke/Cargo.toml
./rust-smoke/target/debug/rust-smoke
printf 'default:\n    @echo ok\n' > justfile
test "$(just)" = ok
