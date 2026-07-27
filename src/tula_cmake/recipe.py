"""Conan 2 recipe mixin distributed through ``python_requires``."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from conan.tools.cmake import CMakeDeps, CMakeToolchain, cmake_layout

from .models import FeatureMode
from .registry import cmake_cache_variables, load_registry, render_manifest
from .resources import infrastructure_dir

_REGISTRY = load_registry()
_SETTINGS = ("os", "arch", "compiler", "build_type")


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
        """Propagate public system-provider link libraries to consumers."""
        public_features = set(getattr(self, "tula_public_features", ()))
        system_libs = [
            library
            for name, mode in self._providers().items()
            if mode is FeatureMode.SYSTEM and name in public_features
            for library in _REGISTRY.features[name].system_libs
        ]
        self.cpp_info.system_libs.extend(
            library
            for library in system_libs
            if library not in self.cpp_info.system_libs
        )


def feature_registry() -> Any:
    """Expose the immutable registry to Conan diagnostics."""
    return _REGISTRY
