from __future__ import annotations

import pytest
from pydantic import ValidationError

from tula_cmake.models import FeatureRegistry, OptionSpec


def test_option_default_must_be_allowed() -> None:
    with pytest.raises(ValidationError, match="default"):
        OptionSpec(
            values=("one", "two"),
            default="three",
            cmake_variable="DEMO_OPTION",
        )


def test_registry_rejects_unknown_dependencies() -> None:
    with pytest.raises(ValidationError, match="unknown dependencies"):
        FeatureRegistry.model_validate(
            {
                "schema_version": 1,
                "features": {
                    "demo": {
                        "name": "demo",
                        "modes": ["system"],
                        "dependencies": ["missing"],
                    }
                },
            }
        )


def test_registry_rejects_dependency_cycles() -> None:
    with pytest.raises(ValidationError, match="cycle"):
        FeatureRegistry.model_validate(
            {
                "schema_version": 1,
                "features": {
                    "one": {
                        "name": "one",
                        "modes": ["system"],
                        "dependencies": ["two"],
                    },
                    "two": {
                        "name": "two",
                        "modes": ["system"],
                        "dependencies": ["one"],
                    },
                },
            }
        )
