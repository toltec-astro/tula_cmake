from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Annotated

import yaml
from pydantic import BaseModel, ConfigDict, Field, StringConstraints

from tula_cmake.models import FeatureMode, FeatureRegistry, Identifier

Capability = Annotated[
    str,
    StringConstraints(pattern=r"^[a-z][a-z0-9_-]*$"),
]


class ValueOverride(BaseModel):
    model_config = ConfigDict(extra="forbid", frozen=True)

    options: dict[Identifier, str] = Field(default_factory=dict)
    capabilities: tuple[Capability, ...] = ()
    profile_env: str | None = None


class OptionAxis(BaseModel):
    model_config = ConfigDict(extra="forbid", frozen=True)

    mode: FeatureMode
    common_options: dict[Identifier, str] = Field(default_factory=dict)
    capabilities: tuple[Capability, ...] = ()
    values: dict[str, ValueOverride] = Field(default_factory=dict)


class FeatureTestSpec(BaseModel):
    model_config = ConfigDict(extra="forbid", frozen=True)

    probe: str
    provider_options: dict[Identifier, str] = Field(default_factory=dict)
    dependencies: dict[Identifier, FeatureMode] = Field(default_factory=dict)
    provider_capabilities: dict[FeatureMode, tuple[Capability, ...]] = Field(
        default_factory=dict
    )
    option_axes: dict[Identifier, OptionAxis] = Field(default_factory=dict)


class MatrixCatalog(BaseModel):
    model_config = ConfigDict(extra="forbid", frozen=True)

    schema_version: int = Field(ge=1)
    features: dict[Identifier, FeatureTestSpec]

    def validate_for(self, registry: FeatureRegistry) -> None:
        missing = registry.features.keys() - self.features.keys()
        unknown = self.features.keys() - registry.features.keys()
        if missing or unknown:
            msg = (
                "matrix feature keys do not match registry; "
                f"missing={sorted(missing)}, unknown={sorted(unknown)}"
            )
            raise ValueError(msg)

        for name, contract in self.features.items():
            feature = registry.features[name]
            option_names = feature.options.keys()
            if contract.option_axes.keys() != option_names:
                missing_axes = option_names - contract.option_axes.keys()
                unknown_axes = contract.option_axes.keys() - option_names
                msg = (
                    f"{name}: option axes do not match feature options; "
                    f"missing={sorted(missing_axes)}, unknown={sorted(unknown_axes)}"
                )
                raise ValueError(msg)
            self._validate_options(name, contract.provider_options, registry)
            for dependency, mode in contract.dependencies.items():
                if dependency not in feature.dependencies:
                    raise ValueError(f"{name}: undeclared dependency {dependency!r}")
                self._validate_mode(dependency, mode, registry)
            for mode in contract.provider_capabilities:
                self._validate_mode(name, mode, registry)
            for option_name, axis in contract.option_axes.items():
                self._validate_mode(name, axis.mode, registry)
                self._validate_options(name, axis.common_options, registry)
                unknown_values = axis.values.keys() - set(
                    feature.options[option_name].values
                )
                if unknown_values:
                    raise ValueError(
                        f"{name}.{option_name}: unknown test values "
                        f"{sorted(unknown_values)}"
                    )
                for override in axis.values.values():
                    self._validate_options(name, override.options, registry)

    @staticmethod
    def _validate_mode(
        feature_name: str,
        mode: FeatureMode,
        registry: FeatureRegistry,
    ) -> None:
        if (
            mode is not FeatureMode.DISABLED
            and mode not in registry.features[feature_name].modes
        ):
            raise ValueError(f"{feature_name}: unsupported matrix mode {mode.value}")

    @staticmethod
    def _validate_options(
        feature_name: str,
        values: dict[str, str],
        registry: FeatureRegistry,
    ) -> None:
        options = registry.features[feature_name].options
        unknown = values.keys() - options.keys()
        if unknown:
            msg = f"{feature_name}: unknown matrix options {sorted(unknown)}"
            raise ValueError(msg)
        for option_name, value in values.items():
            if value not in options[option_name].values:
                msg = (
                    f"{feature_name}.{option_name}: unsupported matrix value {value!r}"
                )
                raise ValueError(msg)

    def cases(self, registry: FeatureRegistry) -> tuple[MatrixCase, ...]:
        self.validate_for(registry)
        cases: list[MatrixCase] = []
        for feature_name, contract in self.features.items():
            feature = registry.features[feature_name]
            defaults = {
                name: option.default for name, option in feature.options.items()
            }
            cases.extend(
                MatrixCase(
                    id=f"{feature_name}--{mode.value}",
                    feature=feature_name,
                    mode=mode,
                    probe=contract.probe,
                    options={**defaults, **contract.provider_options},
                    dependencies=contract.dependencies,
                    capabilities=contract.provider_capabilities.get(mode, ()),
                    profile_env=None,
                    network=mode in {FeatureMode.CONAN, FeatureMode.CPM},
                )
                for mode in (FeatureMode.DISABLED, *feature.modes)
            )
            for option_name, axis in contract.option_axes.items():
                for value in feature.options[option_name].values:
                    override = axis.values.get(value, ValueOverride())
                    cases.append(
                        MatrixCase(
                            id=f"{feature_name}--{option_name}--{value}",
                            feature=feature_name,
                            mode=axis.mode,
                            probe=contract.probe,
                            options={
                                **defaults,
                                **axis.common_options,
                                **override.options,
                                option_name: value,
                            },
                            dependencies=contract.dependencies,
                            capabilities=(
                                *axis.capabilities,
                                *override.capabilities,
                            ),
                            profile_env=override.profile_env,
                            network=axis.mode in {FeatureMode.CONAN, FeatureMode.CPM},
                        )
                    )
        return tuple(cases)


@dataclass(frozen=True)
class MatrixCase:
    id: str
    feature: str
    mode: FeatureMode
    probe: str
    options: dict[str, str]
    dependencies: dict[str, FeatureMode]
    capabilities: tuple[str, ...]
    profile_env: str | None
    network: bool

    def conan_options(self, registry: FeatureRegistry) -> tuple[str, ...]:
        values = dict.fromkeys(registry.features, FeatureMode.DISABLED.value)
        values.update({name: mode.value for name, mode in self.dependencies.items()})
        values[self.feature] = self.mode.value
        for feature in registry.features.values():
            for name, option in feature.options.items():
                values[name] = option.default
        values.update(self.options)
        return tuple(f"{name}={value}" for name, value in values.items())


def load_catalog(path: Path) -> MatrixCatalog:
    raw = yaml.safe_load(path.read_text())
    return MatrixCatalog.model_validate(raw)
