"""Conan 2 recipe mixin distributed through ``python_requires``."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from conan.tools.cmake import CMakeDeps, CMakeToolchain, cmake_layout

from .models import FeatureMode
from .registry import load_registry, render_manifest
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
        for name, mode in self._providers().items():
            if mode is not FeatureMode.CONAN:
                continue
            for requirement in _REGISTRY.features[name].conan_requires:
                self.output.info(f"{name}: Conan provider requires {requirement}")
                self.requires(requirement)

    def generate(self: Any) -> None:
        """Generate CMake dependency files, toolchain, and Tula manifest."""
        generators = Path(self.generators_folder)
        manifest = generators / "tula_features.cmake"
        manifest.write_text(
            render_manifest(
                _REGISTRY,
                self._providers(),
                self._option_values(),
            )
        )

        CMakeDeps(self).generate()
        toolchain = CMakeToolchain(self)
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


def feature_registry() -> Any:
    """Expose the immutable registry to Conan diagnostics."""
    return _REGISTRY
