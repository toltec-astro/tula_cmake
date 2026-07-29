"""Stable accessors for resources installed with :mod:`tula_cmake`."""

from __future__ import annotations

from importlib.resources import files
from pathlib import Path

_DATA = files("tula_cmake").joinpath("data")


def data_path(*parts: str) -> Path:
    """Return an installed package-data path.

    ``tula_cmake`` is distributed as an unpacked wheel and as Conan exported
    sources, so the traversable resource has a concrete filesystem path in both
    supported execution environments.
    """
    return Path(str(_DATA.joinpath(*parts)))


def cmake_dir() -> Path:
    """Return the root directory containing packaged CMake resources."""
    return data_path("cmake")


def infrastructure_dir() -> Path:
    """Return public superbuild infrastructure modules for ``CMAKE_MODULE_PATH``."""
    return cmake_dir() / "infrastructure"


def resolvers_dir() -> Path:
    """Return convention-based feature resolver modules."""
    return cmake_dir() / "resolvers"


def resolver_path(feature: str) -> Path:
    """Return the resolver module derived from a validated feature name."""
    return resolvers_dir() / f"{feature}.cmake"


def profiles_dir() -> Path:
    """Return the directory containing bundled Conan profiles."""
    return data_path("profiles")


def recipes_dir() -> Path:
    """Return the directory containing project-owned Conan recipes."""
    return data_path("recipes")


def recipe_dir(name: str) -> Path:
    """Return one bundled project-owned Conan recipe directory."""
    path = recipes_dir() / name
    if not (path / "conanfile.py").is_file():
        raise ValueError(f"unknown bundled recipe: {name}")
    return path


def registry_path() -> Path:
    """Return the feature registry path."""
    return data_path("registry.yaml")


def project_catalog_path() -> Path:
    """Return the owned-project source catalog path."""
    return data_path("projects.yaml")


def template_path(name: str) -> Path:
    """Return one bundled code-generation template."""
    return data_path("templates", name)
