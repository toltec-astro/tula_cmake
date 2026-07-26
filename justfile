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

cruft-check:
    uvx cruft check --checkout v2026

cruft-update:
    uvx cruft update --checkout v2026
