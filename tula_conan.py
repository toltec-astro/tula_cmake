"""Conan 2 recipe base for Tula feature/provider selection."""

from __future__ import annotations

from pathlib import Path
from typing import Any, cast

from conan import ConanFile
from conan.tools.cmake import CMakeDeps, CMakeToolchain, cmake_layout

from .model import FeatureMode, load_feature_registry, render_cmake_manifest, validate_selection

_PACKAGE_ROOT = Path(__file__).parent
_REGISTRY = load_feature_registry()
_LOG_LEVELS = ("trace", "debug", "info", "warning", "error", "critical", "off")


def _static_block(content: str) -> type:
    class StaticBlock:
        template = "{{ content }}"

        def context(self) -> dict[str, str]:
            return {"content": content}

    return StaticBlock


class TulaConan(ConanFile):
    """Minimal Conan integration; CPM and system remain explicit Tula providers."""

    required_conan_version = ">=2.30"
    settings = "os", "arch", "compiler", "build_type"
    options = {
        **{name: feature.option_values for name, feature in _REGISTRY.items()},
        "logging_level": _LOG_LEVELS,
    }
    default_options = {
        **{name: FeatureMode.DISABLED.value for name in _REGISTRY},
        "logging_level": "info",
    }

    def layout(self) -> None:
        cmake_layout(self)

    def _selection(self) -> dict[str, FeatureMode]:
        selected = {name: FeatureMode(str(getattr(self.options, name))) for name in _REGISTRY}
        validate_selection(_REGISTRY, selected)
        return selected

    def requirements(self) -> None:
        for name, mode in self._selection().items():
            if mode is not FeatureMode.CONAN:
                continue
            for requirement in _REGISTRY[name].conan_requires:
                self.output.info(f"{name}: Conan provider requires {requirement}")
                cast(Any, self.requires)(requirement)

    def generate(self) -> None:
        selected = self._selection()
        generators = Path(self.generators_folder)
        manifest = generators / "tula_features.cmake"
        manifest.write_text(
            render_cmake_manifest(
                _REGISTRY,
                selected,
                logging_level=str(cast(Any, self.options).logging_level),
            )
        )

        CMakeDeps(self).generate()
        toolchain = CMakeToolchain(self)
        toolchain.blocks["tula_feature_entrypoint"] = _static_block(
            "\n".join(
                [
                    "########## tula feature/provider entrypoint ##########",
                    f'list(PREPEND CMAKE_MODULE_PATH "{_PACKAGE_ROOT / "cmake"}")',
                    f'set(TULA_FEATURE_MANIFEST "{manifest}")',
                    "",
                ]
            )
        )
        toolchain.generate()


def feature_registry() -> Any:
    """Expose the immutable registry for diagnostics and tests."""
    return _REGISTRY
