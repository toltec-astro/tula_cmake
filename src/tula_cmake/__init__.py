"""Typed Conan 2 and CMake superbuild infrastructure for TolTEC packages."""

from __future__ import annotations

from typing import Any

from .models import (
    FeatureMode,
    FeatureRegistry,
    FeatureSpec,
    OptionSpec,
)
from .registry import load_registry, render_manifest, resolution_order
from .resources import profiles_dir


def __getattr__(name: str) -> Any:
    """Load Conan only when a recipe asks for the mixin."""
    if name == "TulaConan":
        from .recipe import TulaConan

        return TulaConan
    raise AttributeError(name)


__all__ = [
    "FeatureMode",
    "FeatureRegistry",
    "FeatureSpec",
    "OptionSpec",
    "TulaConan",
    "load_registry",
    "profiles_dir",
    "render_manifest",
    "resolution_order",
]
