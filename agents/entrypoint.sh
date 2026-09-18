#!/bin/sh
set -eu

if [ "$#" -eq 0 ]; then
    set -- opencode
fi

case "$1" in
    dsh)
        shift
        exec dsh web --no-open "$@"
        ;;
    opencode)
        shift
        exec opencode serve --hostname 0.0.0.0 --port 4096 "$@"
        ;;
    *)
        exec "$@"
        ;;
esac
