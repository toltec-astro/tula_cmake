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
    """Return the directory containing public CMake modules."""
    return data_path("cmake")


def profiles_dir() -> Path:
    """Return the directory containing bundled Conan profiles."""
    return data_path("profiles")


def registry_path() -> Path:
    """Return the feature registry path."""
    return data_path("registry.yaml")


def template_path(name: str) -> Path:
    """Return one bundled code-generation template."""
    return data_path("templates", name)
