from __future__ import annotations

from pathlib import Path

import pytest

import tula_cmake
from tula_cmake import profiles_dir
from tula_cmake.models import FeatureMode
from tula_cmake.registry import (
    cmake_cache_variables,
    load_registry,
    render_manifest,
    resolution_order,
)
from tula_cmake.resources import infrastructure_dir, resolver_path, template_path


def _defaults() -> tuple[dict[str, FeatureMode], dict[str, str]]:
    registry = load_registry()
    providers = dict.fromkeys(registry.features, FeatureMode.DISABLED)
    options = {
        name: option.default
        for feature in registry.features.values()
        for name, option in feature.options.items()
    }
    return providers, options


def test_registry_has_current_feature_slice() -> None:
    registry = load_registry()
    assert tuple(registry.features) == (
        "logging",
        "yaml_cpp",
        "csv_parser",
        "netcdf_c",
        "netcdf_cxx4",
        "bitmask",
        "meta_enum",
        "clipp",
        "perflibs",
        "eigen",
        "spectra",
        "boost",
        "fftw",
        "ccfits",
        "ceres",
        "grppi",
    )
    assert registry.features["logging"].conan_requires == (
        "fmt/12.1.0",
        "spdlog/1.17.0",
    )
    assert registry.features["perflibs"].option_values == (
        "disabled",
        "system",
    )
    assert registry.features["yaml_cpp"].conan_requires == ("yaml-cpp/0.9.0",)
    assert registry.features["netcdf_c"].conan_requires == ("netcdf/4.8.1",)
    assert registry.features["clipp"].modes == (FeatureMode.CPM,)
    assert registry.features["clipp"].cmake_vars["GIT_TAG"] == (
        "ddf69f70eaaefe318cc8aa0d018ff523111410bb"
    )
    assert registry.features["eigen"].conan_requires == ("eigen/3.4.0",)
    assert registry.features["spectra"].conan_requires == ("spectra/1.0.1",)
    assert registry.features["boost"].conan_requires == ("boost/1.91.0",)
    assert registry.features["fftw"].conan_requires == ("fftw/3.3.10",)
    assert registry.features["ccfits"].conan_requires == ("ccfits/2.6",)
    assert registry.features["ceres"].conan_requires == ("ceres-solver/2.2.0",)
    assert resolution_order(registry) == (
        "logging",
        "yaml_cpp",
        "csv_parser",
        "netcdf_c",
        "netcdf_cxx4",
        "bitmask",
        "meta_enum",
        "clipp",
        "perflibs",
        "eigen",
        "spectra",
        "boost",
        "fftw",
        "ccfits",
        "ceres",
        "grppi",
    )


def test_manifest_records_only_providers_and_immutable_data() -> None:
    registry = load_registry()
    providers, _ = _defaults()
    providers["logging"] = FeatureMode.SYSTEM
    providers["perflibs"] = FeatureMode.SYSTEM
    manifest = render_manifest(registry, providers)
    assert (
        'set(TULA_FEATURES "logging;yaml_cpp;csv_parser;netcdf_c;netcdf_cxx4;'
        "bitmask;meta_enum;clipp;perflibs;eigen;spectra;boost;fftw;ccfits;"
        'ceres;grppi")' in manifest
    )
    assert 'set(TULA_FEATURE_logging_MODE "system")' in manifest
    assert f'"{resolver_path("logging").resolve()}"' in manifest
    assert "TULA_LOGGING_LEVEL" not in manifest
    assert "TULA_PERFLIBS_OPENMP" not in manifest


def test_options_become_generated_preset_cache_variables() -> None:
    registry = load_registry()
    providers, options = _defaults()
    providers["logging"] = FeatureMode.SYSTEM
    providers["perflibs"] = FeatureMode.SYSTEM
    options["logging_level"] = "warning"
    options["perflibs_openmp"] = "required"
    cache = cmake_cache_variables(registry, providers, options)
    assert cache["TULA_LOGGING_LEVEL"] == "warning"
    assert cache["TULA_PERFLIBS_OPENMP"] == "required"


def test_cache_variables_require_every_option() -> None:
    registry = load_registry()
    providers, options = _defaults()
    del options["logging_level"]
    with pytest.raises(ValueError, match="option keys"):
        cmake_cache_variables(registry, providers, options)


def test_disabled_feature_options_are_not_emitted() -> None:
    registry = load_registry()
    providers, options = _defaults()
    providers["perflibs"] = FeatureMode.SYSTEM
    cache = cmake_cache_variables(registry, providers, options)
    assert "TULA_LOGGING_LEVEL" not in cache
    assert cache["TULA_PERFLIBS_OPENMP"] == "auto"


def test_registry_rejects_missing_resolver_module(tmp_path: Path) -> None:
    (tmp_path / "cmake" / "resolvers").mkdir(parents=True)
    registry_file = tmp_path / "registry.yaml"
    registry_file.write_text(
        "schema_version: 1\nfeatures:\n  demo:\n    modes: [system]\n"
    )
    with pytest.raises(ValueError, match="missing resolver module"):
        load_registry(registry_file)


def test_resolver_wiring_is_derived_from_feature_name() -> None:
    registry = load_registry()
    for name, feature in registry.features.items():
        module = resolver_path(name)
        assert module.name == f"{name}.cmake"
        content = module.read_text()
        for mode in feature.modes:
            assert f"function(tula_resolve_{name}_{mode.value})" in content


@pytest.mark.parametrize(
    "name",
    [
        "linux-gcc13-debug",
        "linux-gcc14-debug",
        "linux-clang20-debug",
        "macos-brew-llvm-debug",
    ],
)
def test_bundled_profile_is_discoverable(name: str) -> None:
    assert (profiles_dir() / name).is_file()
    assert template_path("TulaConfig.h.in").is_file()


def test_infrastructure_layout_reaches_shared_templates() -> None:
    relative_template = infrastructure_dir() / ".." / ".." / "templates"
    assert relative_template.resolve() == template_path("TulaConfig.h.in").parent


def test_package_lazily_exposes_conan_mixin() -> None:
    assert tula_cmake.__version__ == "3.1.0"
    assert tula_cmake.TulaConan.__name__ == "TulaConan"
    with pytest.raises(AttributeError):
        tula_cmake.__getattr__("missing")
