"""Validated domain models for the superbuild registry and build workflow."""

from __future__ import annotations

from enum import StrEnum
from pathlib import Path
from typing import Annotated

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    RootModel,
    StringConstraints,
    model_validator,
)

Identifier = Annotated[str, StringConstraints(pattern=r"^[a-z][a-z0-9_]*$")]
CMakeCommand = Annotated[str, StringConstraints(pattern=r"^[A-Za-z_][A-Za-z0-9_]*$")]
CMakeVariable = Annotated[str, StringConstraints(pattern=r"^[A-Z][A-Z0-9_]*$")]
CMakeScalar = str | int | float | bool
CMakeValue = CMakeScalar | tuple[CMakeScalar, ...]


class FeatureMode(StrEnum):
    """Supported acquisition policies for a feature."""

    DISABLED = "disabled"
    CONAN = "conan"
    CPM = "cpm"
    SYSTEM = "system"


class OptionSpec(BaseModel):
    """One Conan option that is forwarded to a CMake variable."""

    model_config = ConfigDict(extra="forbid", frozen=True)

    values: tuple[str, ...] = Field(min_length=1)
    default: str
    cmake_variable: CMakeVariable

    @model_validator(mode="after")
    def default_must_be_allowed(self) -> OptionSpec:
        """Reject defaults which Conan would reject at recipe load time."""
        if self.default not in self.values:
            msg = f"default {self.default!r} is not in {self.values!r}"
            raise ValueError(msg)
        if len(set(self.values)) != len(self.values):
            raise ValueError("option values must be unique")
        return self


class FeatureSpec(BaseModel):
    """Immutable description of one logical CMake feature."""

    model_config = ConfigDict(extra="forbid", frozen=True)

    name: Identifier
    modes: tuple[FeatureMode, ...] = Field(min_length=1)
    dependencies: tuple[Identifier, ...] = ()
    conan_requires: tuple[str, ...] = ()
    cmake_module: str
    resolver: CMakeCommand
    cmake_vars: dict[CMakeVariable, CMakeValue] = Field(default_factory=dict)
    options: dict[Identifier, OptionSpec] = Field(default_factory=dict)

    @model_validator(mode="after")
    def validate_modes_and_requirements(self) -> FeatureSpec:
        """Validate provider invariants local to a feature."""
        if FeatureMode.DISABLED in self.modes:
            raise ValueError("disabled mode is implicit")
        if len(set(self.modes)) != len(self.modes):
            raise ValueError("feature modes must be unique")
        if FeatureMode.CONAN in self.modes and not self.conan_requires:
            raise ValueError("conan mode requires conan_requires")
        return self

    @property
    def option_values(self) -> tuple[str, ...]:
        """Return the complete set of values accepted by Conan."""
        return (FeatureMode.DISABLED.value, *(mode.value for mode in self.modes))


class FeatureRegistry(BaseModel):
    """Complete, cross-validated feature registry."""

    model_config = ConfigDict(extra="forbid", frozen=True)

    schema_version: int = Field(ge=1)
    features: dict[Identifier, FeatureSpec] = Field(min_length=1)

    @model_validator(mode="after")
    def validate_graph(self) -> FeatureRegistry:
        """Validate names, option ownership, dependencies, and graph cycles."""
        option_names: set[str] = set()
        for name, feature in self.features.items():
            if feature.name != name:
                raise ValueError(
                    f"feature key {name!r} does not match {feature.name!r}"
                )
            unknown = set(feature.dependencies) - self.features.keys()
            if unknown:
                raise ValueError(f"{name}: unknown dependencies: {sorted(unknown)}")
            overlap = option_names.intersection(feature.options)
            if overlap:
                raise ValueError(f"duplicate option names: {sorted(overlap)}")
            option_names.update(feature.options)

        visiting: set[str] = set()
        visited: set[str] = set()

        def visit(name: str) -> None:
            if name in visiting:
                raise ValueError(f"feature dependency cycle includes {name}")
            if name in visited:
                return
            visiting.add(name)
            for dependency in self.features[name].dependencies:
                visit(dependency)
            visiting.remove(name)
            visited.add(name)

        for name in self.features:
            visit(name)
        return self


class FeatureSelection(RootModel[dict[Identifier, FeatureMode]]):
    """Provider choice for every feature in a registry."""

    model_config = ConfigDict(frozen=True)

    def validate_for(self, registry: FeatureRegistry) -> None:
        """Validate completeness, supported modes, and enabled prerequisites."""
        missing = registry.features.keys() - self.root.keys()
        unknown = self.root.keys() - registry.features.keys()
        if missing or unknown:
            msg = (
                "selection keys do not match registry; "
                f"missing={sorted(missing)}, unknown={sorted(unknown)}"
            )
            raise ValueError(msg)
        for name, feature in registry.features.items():
            mode = self.root[name]
            if mode is not FeatureMode.DISABLED and mode not in feature.modes:
                raise ValueError(f"{name}: unsupported mode {mode.value!r}")
            if mode is FeatureMode.DISABLED:
                continue
            for dependency in feature.dependencies:
                if self.root[dependency] is FeatureMode.DISABLED:
                    raise ValueError(f"{name} requires enabled feature {dependency}")


class BuildRequest(BaseModel):
    """Validated inputs for the one-command downstream workflow."""

    model_config = ConfigDict(extra="forbid", frozen=True)

    source: Path
    output: Path
    profiles: tuple[str, ...] = ()
    config_source: str | None = None
    preset: str | None = None
    build_policy: str = "missing"


class BuildPreset(BaseModel):
    """Subset of a CMake build-preset object used by the workflow."""

    model_config = ConfigDict(extra="ignore", frozen=True)

    name: str


class GeneratedPresets(BaseModel):
    """Subset of a Conan-generated CMake presets document."""

    model_config = ConfigDict(extra="ignore", frozen=True)

    buildPresets: tuple[BuildPreset, ...] = ()  # noqa: N815


class UserPresets(BaseModel):
    """Subset of CMakeUserPresets.json needed to locate Conan output."""

    model_config = ConfigDict(extra="ignore", frozen=True)

    include: tuple[str, ...] = ()
