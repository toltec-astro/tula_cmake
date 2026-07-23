"""Tula's Conan-driven feature/provider integration."""

from __future__ import annotations

from pathlib import Path

from .model import FeatureMode, FeatureSpec, load_feature_registry, render_cmake_manifest


def profiles_dir() -> Path:
    """Return the profiles shipped with this installed distribution."""
    return Path(__file__).parent / "profiles"


def __getattr__(name: str):
    if name == "TulaConan":
        from .tula_conan import TulaConan

        return TulaConan
    raise AttributeError(name)


__all__ = [
    "FeatureMode",
    "FeatureSpec",
    "TulaConan",
    "load_feature_registry",
    "profiles_dir",
    "render_cmake_manifest",
]
