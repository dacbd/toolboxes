set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

default:
    @just --list
    @printf '\nDebug recipes:\n'
    @just --justfile debug/justfile --list
    @printf '\nAgents recipes:\n'
    @just --justfile agents/justfile --list

# Install Trivy if it is not already available on PATH.
setup:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v trivy >/dev/null 2>&1; then
        trivy --version
        exit 0
    fi
    case "$(uname -s)" in
        Darwin)
            command -v brew >/dev/null || { echo "Install Homebrew first: https://brew.sh" >&2; exit 1; }
            brew install trivy
            ;;
        Linux)
            as_root() {
                if [ "$(id -u)" -eq 0 ]; then
                    "$@"
                else
                    sudo "$@"
                fi
            }
            if command -v apt-get >/dev/null 2>&1; then
                as_root apt-get update
                as_root apt-get install -y ca-certificates curl gnupg
                setup_tmp=$(mktemp -d)
                trap 'rm -rf "$setup_tmp"' EXIT
                curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key -o "$setup_tmp/public.key"
                gpg --batch --dearmor --output "$setup_tmp/trivy.gpg" "$setup_tmp/public.key"
                as_root install -d -m 755 /usr/share/keyrings /etc/apt/sources.list.d
                as_root install -m 644 "$setup_tmp/trivy.gpg" /usr/share/keyrings/trivy.gpg
                echo 'deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main' | as_root tee /etc/apt/sources.list.d/trivy.list >/dev/null
                as_root apt-get update
                as_root apt-get install -y trivy
            elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
                rpm_manager=dnf
                command -v dnf >/dev/null 2>&1 || rpm_manager=yum
                as_root install -d -m 755 /etc/yum.repos.d
                printf '%s\n' '[trivy]' 'name=Trivy repository' 'baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$basearch/' 'gpgcheck=1' 'enabled=1' 'gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key' | as_root tee /etc/yum.repos.d/trivy.repo >/dev/null
                as_root "$rpm_manager" install -y trivy
            else
                echo "Unsupported Linux package manager; install Trivy using https://trivy.dev/docs/latest/getting-started/installation/" >&2
                exit 1
            fi
            ;;
        *)
            echo "Unsupported operating system: $(uname -s)" >&2
            exit 1
            ;;
    esac
    trivy --version

# Run a debug image recipe, for example: just debug build
debug *args:
    @just --justfile debug/justfile {{args}}

# Run an agents image recipe, for example: just agents smoke
agents *args:
    @just --justfile agents/justfile {{args}}
