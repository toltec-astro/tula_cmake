from __future__ import annotations

import pytest
from pydantic import ValidationError

from tula_cmake.models import (
    BuildRequest,
    FeatureRegistry,
    OptionSpec,
    ProjectCatalog,
)


def test_option_default_must_be_allowed() -> None:
    with pytest.raises(ValidationError, match="default"):
        OptionSpec(
            values=("one", "two"),
            default="three",
            cmake_variable="DEMO_OPTION",
        )


def test_build_request_rejects_unscoped_option_text() -> None:
    with pytest.raises(ValidationError, match="options"):
        BuildRequest(source=".", output=".tula", options=("not-an-assignment",))

    with pytest.raises(ValidationError, match="project_sources"):
        BuildRequest(source=".", output=".tula", project_sources=("not-a-path",))


def test_project_catalog_rejects_ambiguous_or_unsafe_identity() -> None:
    entry = {
        "name": "actual",
        "version": "1.0.0",
        "source": {
            "git_repository": "https://example.invalid/project.git",
            "git_revision": "0" * 40,
            "source_subdir": "../outside",
        },
        "cmake_target": "actual::target",
    }
    with pytest.raises(ValidationError, match="source_subdir"):
        ProjectCatalog.model_validate(
            {"schema_version": 1, "projects": {"actual": entry}}
        )

    entry["source"]["source_subdir"] = "src"
    with pytest.raises(ValidationError, match="does not match"):
        ProjectCatalog.model_validate(
            {"schema_version": 1, "projects": {"alias": entry}}
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


def test_system_libraries_require_system_provider() -> None:
    with pytest.raises(ValidationError, match="system_libs requires"):
        FeatureRegistry.model_validate(
            {
                "schema_version": 1,
                "features": {
                    "demo": {
                        "name": "demo",
                        "modes": ["cpm"],
                        "system_libs": ["demo"],
                    }
                },
            }
        )


def test_system_link_command_requires_system_provider() -> None:
    with pytest.raises(ValidationError, match="system_link_command requires"):
        FeatureRegistry.model_validate(
            {
                "schema_version": 1,
                "features": {
                    "demo": {
                        "name": "demo",
                        "modes": ["cpm"],
                        "system_link_command": ["demo-config", "--libs"],
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
