# Development tasks for tula-cmake.

default:
    @just --list

sync:
    uv sync --all-groups

format:
    uv run ruff format .
    uv run ruff check --fix .

qa:
    uv run ruff format --check .
    uv run ruff check .
    uv run ty check
    uv run coverage run -m pytest
    uv run coverage report

test:
    uv run pytest

matrix:
    uv run conan export .
    uv run pytest -m "feature_matrix and not network" -vv

matrix-all:
    uv run conan export .
    uv run pytest -m feature_matrix -vv

matrix-list:
    uv run pytest -m feature_matrix --collect-only -q

build:
    uv build

docs:
    uv run --group docs sphinx-build -M html docs docs/_build -T -W

# Prove root-owned provider selection across a transitive CPM source project.
vertical-slice: sync
    #!/usr/bin/env bash
    set -euo pipefail
    root="$(pwd)"
    downstream="$root/examples/tula_downstream"
    run_root="$(mktemp -d /tmp/tula-vertical-slice.XXXXXX)"
    trap 'rm -rf "$run_root"' EXIT
    profile="$(uv run tula-cmake profile linux-gcc13-debug)"
    catalog="$run_root/projects.yaml"
    cp "$root/src/tula_cmake/data/projects.yaml" "$catalog"
    sed -i "s#https://github.com/toltec-astro/tula_cmake.git#$root#" "$catalog"

    uv run tula-cmake build "$downstream" \
        --output "$run_root/conan" \
        --profile "$profile" \
        --catalog "$catalog" \
        --source-cache "$run_root/source-cache"
    conan_output="$("$run_root/conan/build/bin/tula_downstream")"
    printf '%s\n' "$conan_output"
    grep -F 'source-superbuild logging provider: conan' <<<"$conan_output"
    grep -F 'fmt/12.1.0' "$run_root/conan/generated/conanfile.txt"
    grep -F 'spdlog/1.17.0' "$run_root/conan/generated/conanfile.txt"
    ! grep -F 'tula-boilerplate' "$run_root/conan/generated/conanfile.txt"
    grep -F 'TULA_PROJECT_tula_boilerplate_MODE "cpm"' \
        "$run_root/conan/generated/tula_projects.cmake"
    grep -F 'kind: catalog' \
        "$run_root/conan/generated/tula-project-lock.yaml"
    grep -F 'git_revision: 6071444782d913f6294685552bc6a8913c2a121d' \
        "$run_root/conan/generated/tula-project-lock.yaml"

    uv run tula-cmake build "$downstream" \
        --output "$run_root/system" \
        --profile "$profile" \
        --provider logging=system \
        --catalog "$catalog" \
        --project-source "tula_boilerplate=$root/examples/tula_boilerplate"
    system_output="$("$run_root/system/build/bin/tula_downstream")"
    printf '%s\n' "$system_output"
    grep -F 'source-superbuild logging provider: system' <<<"$system_output"
    ! grep -F 'fmt/' "$run_root/system/generated/conanfile.txt"
    ! grep -F 'spdlog/' "$run_root/system/generated/conanfile.txt"
    grep -F 'kind: local' \
        "$run_root/system/generated/tula-project-lock.yaml"

cruft-check:
    uv tool run cruft check --checkout v2026

cruft-update:
    uv tool run cruft update --checkout v2026
