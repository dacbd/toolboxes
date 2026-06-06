set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

default:
    @just --list
    @printf '\nDebug recipes:\n'
    @just --justfile debug/justfile --list
    @printf '\nAgents recipes:\n'
    @just --justfile agents/justfile --list

# Run a debug image recipe, for example: just debug build
debug *args:
    @just --justfile debug/justfile {{args}}

# Run an agents image recipe, for example: just agents smoke
agents *args:
    @just --justfile agents/justfile {{args}}
