"""Pure feature-registry model shared by Conan generation and unit tests."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from types import MappingProxyType
from typing import TypeAlias, cast

import yaml

CMakeScalar: TypeAlias = str | int | float | bool
CMakeValue: TypeAlias = CMakeScalar | tuple[CMakeScalar, ...]
_SCALAR_TYPES = (str, int, float, bool)


class FeatureMode(str, Enum):
    """Supported feature acquisition policies."""

    DISABLED = "disabled"
    CONAN = "conan"
    CPM = "cpm"
    SYSTEM = "system"


@dataclass(frozen=True)
class FeatureSpec:
    """Validated immutable description of one logical feature."""

    name: str
    modes: tuple[FeatureMode, ...]
    dependencies: tuple[str, ...]
    conan_requires: tuple[str, ...]
    cmake_module: Path
    resolver: str
    cmake_vars: Mapping[str, CMakeValue]

    @property
    def option_values(self) -> tuple[str, ...]:
        return tuple(mode.value for mode in self.modes)


def _normalize_cmake_value(feature: str, key: str, value: object) -> CMakeValue:
    if isinstance(value, _SCALAR_TYPES):
        return value
    if isinstance(value, list) and all(isinstance(item, _SCALAR_TYPES) for item in value):
        return tuple(cast(list[CMakeScalar], value))
    raise ValueError(f"{feature}: unsupported CMake value for {key}: {value!r}")


def load_feature_registry(
    registry_file: Path | None = None,
) -> Mapping[str, FeatureSpec]:
    """Load, validate, and freeze the feature registry."""
    package_root = Path(__file__).parent
    source = registry_file or package_root / "features.yaml"
    module_root = package_root / "cmake" if registry_file is None else source.parent / "cmake"
    raw = yaml.safe_load(source.read_text())
    if not isinstance(raw, dict) or not raw:
        raise ValueError(f"Feature registry must be a non-empty mapping: {source}")

    registry: dict[str, FeatureSpec] = {}
    for name, value in raw.items():
        if not isinstance(name, str) or not isinstance(value, dict):
            raise ValueError(f"Invalid feature entry: {name!r}")

        raw_modes = value.get("modes")
        if not isinstance(raw_modes, list) or not raw_modes:
            raise ValueError(f"{name}: modes must be a non-empty list")
        try:
            enabled_modes = tuple(FeatureMode(mode) for mode in raw_modes)
        except (TypeError, ValueError) as error:
            raise ValueError(f"{name}: unsupported mode in {raw_modes!r}") from error
        if FeatureMode.DISABLED in enabled_modes:
            raise ValueError(f"{name}: disabled is implicit")
        if len(set(enabled_modes)) != len(enabled_modes):
            raise ValueError(f"{name}: duplicate modes")

        dependencies = value.get("dependencies", [])
        requirements = value.get("conan_requires", [])
        if not isinstance(dependencies, list) or not all(
            isinstance(item, str) for item in dependencies
        ):
            raise ValueError(f"{name}: dependencies must be a list of strings")
        if not isinstance(requirements, list) or not all(
            isinstance(item, str) for item in requirements
        ):
            raise ValueError(f"{name}: conan_requires must be a list of strings")
        if FeatureMode.CONAN in enabled_modes and not requirements:
            raise ValueError(f"{name}: conan mode requires conan_requires")

        module_name = value.get("cmake_module")
        if not isinstance(module_name, str):
            raise ValueError(f"{name}: cmake_module must be a string")
        module = module_root / module_name
        if not module.is_file():
            raise ValueError(f"{name}: missing CMake module: {module}")

        resolver = value.get("resolver")
        if not isinstance(resolver, str) or not resolver.replace("_", "").isalnum():
            raise ValueError(f"{name}: resolver must be a CMake command name")

        raw_vars = value.get("cmake_vars", {})
        if not isinstance(raw_vars, dict):
            raise ValueError(f"{name}: cmake_vars must be a mapping")
        cmake_vars = {
            key: _normalize_cmake_value(name, key, item)
            for key, item in raw_vars.items()
            if isinstance(key, str)
        }
        if len(cmake_vars) != len(raw_vars):
            raise ValueError(f"{name}: CMake variable names must be strings")

        registry[name] = FeatureSpec(
            name=name,
            modes=(FeatureMode.DISABLED, *enabled_modes),
            dependencies=tuple(cast(list[str], dependencies)),
            conan_requires=tuple(cast(list[str], requirements)),
            cmake_module=module,
            resolver=resolver,
            cmake_vars=MappingProxyType(cmake_vars),
        )

    for feature in registry.values():
        unknown = set(feature.dependencies) - registry.keys()
        if unknown:
            raise ValueError(f"{feature.name}: unknown dependencies: {sorted(unknown)}")
    _validate_acyclic(registry)
    return MappingProxyType(registry)


def _validate_acyclic(registry: Mapping[str, FeatureSpec]) -> None:
    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(name: str) -> None:
        if name in visiting:
            raise ValueError(f"Feature dependency cycle includes {name}")
        if name in visited:
            return
        visiting.add(name)
        for dependency in registry[name].dependencies:
            visit(dependency)
        visiting.remove(name)
        visited.add(name)

    for name in registry:
        visit(name)


def validate_selection(
    registry: Mapping[str, FeatureSpec],
    selected: Mapping[str, FeatureMode],
) -> None:
    """Reject unsupported providers and disabled prerequisites."""
    missing = registry.keys() - selected.keys()
    unknown = selected.keys() - registry.keys()
    if missing or unknown:
        raise ValueError(
            "Selection keys do not match registry; "
            f"missing={sorted(missing)}, unknown={sorted(unknown)}"
        )
    for name, feature in registry.items():
        mode = selected[name]
        if mode not in feature.modes:
            raise ValueError(f"{name}: mode {mode.value!r} is not supported")
        if mode is FeatureMode.DISABLED:
            continue
        for dependency in feature.dependencies:
            if selected[dependency] is FeatureMode.DISABLED:
                raise ValueError(f"{name} requires enabled feature {dependency}")


def resolution_order(registry: Mapping[str, FeatureSpec]) -> tuple[str, ...]:
    """Return a stable dependency-first order for feature resolution."""
    ordered: list[str] = []
    visited: set[str] = set()

    def visit(name: str) -> None:
        if name in visited:
            return
        for dependency in registry[name].dependencies:
            visit(dependency)
        visited.add(name)
        ordered.append(name)

    for name in registry:
        visit(name)
    return tuple(ordered)


def _cmake_quote(value: CMakeValue) -> str:
    text = ";".join(str(item) for item in value) if isinstance(value, tuple) else str(value)
    return text.replace("\\", "\\\\").replace('"', '\\"')


def render_cmake_manifest(
    registry: Mapping[str, FeatureSpec],
    selected: Mapping[str, FeatureMode],
    *,
    logging_level: str,
) -> str:
    """Render deterministic input for the post-project CMake resolver."""
    validate_selection(registry, selected)
    ordered = resolution_order(registry)
    lines = [
        "# Generated by tula_cmake. Do not edit.",
        f'set(TULA_FEATURES "{";".join(ordered)}")',
        f'set(TULA_LOGGING_LEVEL "{_cmake_quote(logging_level)}")',
    ]
    for name in ordered:
        feature = registry[name]
        lines.extend(
            [
                f'set(TULA_FEATURE_{name}_MODE "{selected[name].value}")',
                f'set(TULA_FEATURE_{name}_MODULE "{_cmake_quote(str(feature.cmake_module))}")',
                f'set(TULA_FEATURE_{name}_RESOLVER "{_cmake_quote(feature.resolver)}")',
            ]
        )
        for key, value in feature.cmake_vars.items():
            lines.append(f'set(TULA_FEATURE_{name}_{key} "{_cmake_quote(value)}")')
    lines.append("")
    return "\n".join(lines)
