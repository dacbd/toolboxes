#!/bin/sh
set -eu

if [ "$#" -eq 0 ]; then
    set -- opencode2
fi

case "$1" in
    opencode2)
        shift
        exec opencode2 serve --hostname 0.0.0.0 --port 4096 "$@"
        ;;
    *)
        exec "$@"
        ;;
esac
