"""Conan 2 recipe mixin distributed through ``python_requires``."""

from __future__ import annotations

import os
import shlex
import shutil
import subprocess
from pathlib import Path
from typing import Any

from conan.errors import ConanInvalidConfiguration
from conan.tools.cmake import CMakeDeps, CMakeToolchain, cmake_layout

from .models import FeatureMode
from .registry import cmake_cache_variables, load_registry, render_manifest
from .resources import infrastructure_dir

_REGISTRY = load_registry()
_SETTINGS = ("os", "arch", "compiler", "build_type")
_LINK_FLAG_PREFIX_LENGTH = 2


def _append_unique(values: list[str], candidates: tuple[str, ...] | list[str]) -> None:
    """Append candidates while preserving order and removing duplicates."""
    values.extend(candidate for candidate in candidates if candidate not in values)


def _system_link_metadata(
    feature_name: str,
    command: tuple[str, ...],
) -> tuple[list[str], list[str]]:
    """Return library directories and names emitted by a config helper."""
    try:
        link_flags = subprocess.check_output(command, text=True).strip()
    except (OSError, subprocess.CalledProcessError) as error:
        command_text = " ".join(command)
        msg = (
            f"{feature_name}: unable to discover system link metadata "
            f"with {command_text!r}"
        )
        raise ConanInvalidConfiguration(msg) from error
    if not link_flags:
        command_text = " ".join(command)
        msg = f"{feature_name}: {command_text!r} returned empty link metadata"
        raise ConanInvalidConfiguration(msg)
    library_dirs: list[str] = []
    libraries: list[str] = []
    for flag in shlex.split(link_flags):
        if flag.startswith("-L") and len(flag) > _LINK_FLAG_PREFIX_LENGTH:
            library_dirs.append(flag[_LINK_FLAG_PREFIX_LENGTH:])
        elif flag.startswith("-l") and len(flag) > _LINK_FLAG_PREFIX_LENGTH:
            libraries.append(flag[_LINK_FLAG_PREFIX_LENGTH:])
    return library_dirs, libraries


def _system_include_directory(
    feature_name: str,
    command: tuple[str, ...],
) -> str:
    """Return the include directory emitted by a config helper."""
    try:
        include_dir = subprocess.check_output(command, text=True).strip()
    except (OSError, subprocess.CalledProcessError) as error:
        command_text = " ".join(command)
        msg = (
            f"{feature_name}: unable to discover system include metadata "
            f"with {command_text!r}"
        )
        raise ConanInvalidConfiguration(msg) from error
    if not include_dir:
        command_text = " ".join(command)
        msg = f"{feature_name}: {command_text!r} returned empty include metadata"
        raise ConanInvalidConfiguration(msg)
    return include_dir


def _static_block(content: str) -> type:
    """Create a Conan toolchain block containing static CMake."""

    class StaticBlock:
        template = "{{ content }}"

        def context(self) -> dict[str, str]:
            return {"content": content}

    return StaticBlock


class TulaConan:
    """Compose registry-driven options and generators into a Conan recipe."""

    def init(self: Any) -> None:
        """Add Tula settings and registry options to the consuming recipe."""
        existing_settings = tuple(self.settings or ())
        self.settings = tuple(dict.fromkeys((*existing_settings, *_SETTINGS)))
        values = {
            name: feature.option_values for name, feature in _REGISTRY.features.items()
        }
        defaults = dict.fromkeys(
            _REGISTRY.features,
            FeatureMode.DISABLED.value,
        )
        for feature in _REGISTRY.features.values():
            for name, option in feature.options.items():
                values[name] = option.values
                defaults[name] = option.default
        project_defaults = getattr(self, "tula_default_options", {})
        unknown_defaults = project_defaults.keys() - defaults.keys()
        if unknown_defaults:
            unknown = ", ".join(sorted(unknown_defaults))
            raise ValueError(f"unknown Tula default option(s): {unknown}")
        defaults.update(project_defaults)
        self.options.update(values, defaults)

    def layout(self: Any) -> None:
        """Use Conan's standard CMake layout."""
        cmake_layout(self)

    def _providers(self: Any) -> dict[str, FeatureMode]:
        return {
            name: FeatureMode(str(getattr(self.options, name)))
            for name in _REGISTRY.features
        }

    def _option_values(self: Any) -> dict[str, str]:
        return {
            name: str(getattr(self.options, name))
            for feature in _REGISTRY.features.values()
            for name in feature.options
        }

    def requirements(self: Any) -> None:
        """Declare requirements owned by features using the Conan provider."""
        public_features = set(getattr(self, "tula_public_features", ()))
        unknown_public = public_features - _REGISTRY.features.keys()
        if unknown_public:
            unknown = ", ".join(sorted(unknown_public))
            raise ValueError(f"unknown public Tula feature(s): {unknown}")
        for name, mode in self._providers().items():
            if mode is not FeatureMode.CONAN:
                continue
            for requirement in _REGISTRY.features[name].conan_requires:
                self.output.info(f"{name}: Conan provider requires {requirement}")
                is_public = name in public_features
                self.requires(
                    requirement,
                    transitive_headers=is_public,
                    transitive_libs=is_public,
                )

    def generate(self: Any) -> None:
        """Generate CMake dependency files, toolchain, and Tula manifest."""
        generators = Path(self.generators_folder)
        manifest = generators / "tula_features.cmake"
        manifest.write_text(
            render_manifest(
                _REGISTRY,
                self._providers(),
            )
        )

        CMakeDeps(self).generate()
        toolchain = CMakeToolchain(self)
        toolchain.cache_variables.update(
            cmake_cache_variables(
                _REGISTRY,
                self._providers(),
                self._option_values(),
            )
        )
        toolchain.blocks["tula_feature_entrypoint"] = _static_block(
            "\n".join(
                [
                    "########## tula feature/provider entrypoint ##########",
                    f'list(PREPEND CMAKE_MODULE_PATH "{infrastructure_dir()}")',
                    f'set(TULA_FEATURE_MANIFEST "{manifest}")',
                    "",
                ]
            )
        )
        toolchain.generate()

    def package_info(self: Any) -> None:
        """Propagate public system-provider link metadata to consumers."""
        public_features = set(getattr(self, "tula_public_features", ()))
        for name, mode in self._providers().items():
            if mode is not FeatureMode.SYSTEM or name not in public_features:
                continue
            feature = _REGISTRY.features[name]
            _append_unique(self.cpp_info.system_libs, feature.system_libs)
            if feature.system_include_command:
                include_dir = _system_include_directory(
                    name,
                    feature.system_include_command,
                )
                _append_unique(self.cpp_info.includedirs, [include_dir])
            if not feature.system_link_command:
                continue
            library_dirs, libraries = _system_link_metadata(
                name,
                feature.system_link_command,
            )
            _append_unique(self.cpp_info.libdirs, library_dirs)
            _append_unique(self.cpp_info.system_libs, libraries)
        if (
            self._providers().get("perflibs") is FeatureMode.SYSTEM
            and "perflibs" in public_features
            and str(self.options.perflibs_openmp) == "required"
        ):
            self._propagate_required_openmp()

    def _propagate_required_openmp(self: Any) -> None:
        """Publish compiler and linker metadata for required system OpenMP."""
        compile_flags = ["-fopenmp"]
        link_flags = ["-fopenmp"]
        if str(self.settings.os) == "Macos":
            prefix = os.environ.get("OPENMP_ROOT")
            if not prefix:
                brew = shutil.which("brew")
                if not brew:
                    msg = (
                        "perflibs: required AppleClang OpenMP needs OPENMP_ROOT "
                        "or a Homebrew libomp installation"
                    )
                    raise ConanInvalidConfiguration(msg)
                try:
                    prefix = subprocess.check_output(
                        (brew, "--prefix", "libomp"),
                        text=True,
                    ).strip()
                except (OSError, subprocess.CalledProcessError) as error:
                    msg = (
                        "perflibs: required AppleClang OpenMP needs OPENMP_ROOT "
                        "or a Homebrew libomp installation"
                    )
                    raise ConanInvalidConfiguration(msg) from error
            include_dir = str(Path(prefix) / "include")
            library_dir = str(Path(prefix) / "lib")
            _append_unique(self.cpp_info.includedirs, [include_dir])
            _append_unique(self.cpp_info.libdirs, [library_dir])
            _append_unique(self.cpp_info.system_libs, ["omp"])
        _append_unique(self.cpp_info.cxxflags, compile_flags)
        for attribute in ("sharedlinkflags", "exelinkflags"):
            values = getattr(self.cpp_info, attribute)
            _append_unique(values, link_flags)


def feature_registry() -> Any:
    """Expose the immutable registry to Conan diagnostics."""
    return _REGISTRY
