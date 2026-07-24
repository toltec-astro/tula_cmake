from __future__ import annotations

from pathlib import Path

import pytest

import tula_cmake
from tula_cmake import profiles_dir
from tula_cmake.models import FeatureMode
from tula_cmake.registry import load_registry, render_manifest, resolution_order
from tula_cmake.resources import template_path


def _defaults() -> tuple[dict[str, FeatureMode], dict[str, str]]:
    registry = load_registry()
    providers = dict.fromkeys(registry.features, FeatureMode.DISABLED)
    options = {
        name: option.default
        for feature in registry.features.values()
        for name, option in feature.options.items()
    }
    return providers, options


def test_registry_has_logging_meta_feature_and_perflibs() -> None:
    registry = load_registry()
    assert tuple(registry.features) == ("logging", "perflibs")
    assert registry.features["logging"].conan_requires == (
        "fmt/11.2.0",
        "spdlog/1.15.3",
    )
    assert registry.features["perflibs"].option_values == (
        "disabled",
        "system",
    )
    assert resolution_order(registry) == ("logging", "perflibs")


def test_manifest_records_providers_and_feature_options() -> None:
    registry = load_registry()
    providers, options = _defaults()
    providers["logging"] = FeatureMode.SYSTEM
    providers["perflibs"] = FeatureMode.SYSTEM
    options["logging_level"] = "warning"
    options["perflibs_openmp"] = "required"
    manifest = render_manifest(registry, providers, options)
    assert 'set(TULA_FEATURES "logging;perflibs")' in manifest
    assert 'set(TULA_FEATURE_logging_MODE "system")' in manifest
    assert 'set(TULA_LOGGING_LEVEL "warning")' in manifest
    assert 'set(TULA_PERFLIBS_OPENMP "required")' in manifest


def test_manifest_requires_every_option() -> None:
    registry = load_registry()
    providers, options = _defaults()
    del options["logging_level"]
    with pytest.raises(ValueError, match="option keys"):
        render_manifest(registry, providers, options)


def test_registry_rejects_missing_cmake_module(tmp_path: Path) -> None:
    (tmp_path / "cmake").mkdir()
    registry_file = tmp_path / "registry.yaml"
    registry_file.write_text(
        "schema_version: 1\n"
        "features:\n"
        "  demo:\n"
        "    modes: [system]\n"
        "    cmake_module: Missing.cmake\n"
        "    resolver: resolve_demo\n"
    )
    with pytest.raises(ValueError, match="missing CMake module"):
        load_registry(registry_file)


def test_bundled_profile_is_discoverable() -> None:
    assert (profiles_dir() / "linux-gcc13-debug").is_file()
    assert template_path("TulaConfig.h.in").is_file()


def test_package_lazily_exposes_conan_mixin() -> None:
    assert tula_cmake.TulaConan.__name__ == "TulaConan"
    with pytest.raises(AttributeError):
        tula_cmake.__getattr__("missing")
