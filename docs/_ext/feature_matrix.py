"""Render the feature/provider and option reference from the packaged registry."""

from __future__ import annotations

from typing import TYPE_CHECKING

from docutils import nodes
from docutils.parsers.rst import Directive
from docutils.statemachine import StringList

from tula_cmake.models import FeatureMode
from tula_cmake.registry import load_registry
from tula_cmake.resources import registry_path

if TYPE_CHECKING:
    from sphinx.application import Sphinx


def _support(*, enabled: bool) -> str:
    return "yes" if enabled else "—"


def _render_reference() -> str:
    registry = load_registry()
    lines = [
        ".. rubric:: Provider support matrix",
        "",
        "``disabled`` is an implicit provider for every feature and is the",
        "default applied by :class:`tula_cmake.recipe.TulaConan`.",
        "",
        ".. list-table::",
        "   :header-rows: 1",
        "   :widths: 18 12 12 12 12 24",
        "",
        "   * - Feature option",
        "     - Disabled",
        "     - Conan",
        "     - CPM",
        "     - System",
        "     - Normalized target",
    ]
    for name, feature in registry.features.items():
        modes = set(feature.modes)
        lines.extend(
            [
                f"   * - ``{name}``",
                "     - yes",
                f"     - {_support(enabled=FeatureMode.CONAN in modes)}",
                f"     - {_support(enabled=FeatureMode.CPM in modes)}",
                f"     - {_support(enabled=FeatureMode.SYSTEM in modes)}",
                f"     - ``tula::{name}``",
            ]
        )

    lines.extend(
        [
            "",
            ".. rubric:: Conan root-package options",
            "",
            "Each feature contributes a provider option named after the feature.",
            "Additional feature-owned options are forwarded to the listed CMake",
            "cache variables only while that feature is enabled.",
            "",
        ]
    )
    for name, feature in registry.features.items():
        provider_values = ", ".join(
            (FeatureMode.DISABLED.value, *(mode.value for mode in feature.modes))
        )
        requirements = (
            ", ".join(f"``{item}``" for item in feature.conan_requires)
            if feature.conan_requires
            else "none"
        )
        dependencies = (
            ", ".join(f"``{item}``" for item in feature.dependencies)
            if feature.dependencies
            else "none"
        )
        lines.extend(
            [
                f".. rubric:: {name}",
                "",
                f":Provider option: ``{name}``",
                f":Provider values: ``{provider_values}``",
                ":Provider default: ``disabled``",
                f":Feature dependencies: {dependencies}",
                f":Conan requirements: {requirements}",
                "",
            ]
        )
        if not feature.options:
            lines.extend(["No additional options.", ""])
            continue
        lines.extend(
            [
                ".. list-table:: Additional options",
                "   :header-rows: 1",
                "   :widths: 24 32 14 30",
                "",
                "   * - Option",
                "     - Allowed values",
                "     - Default",
                "     - CMake cache variable",
            ]
        )
        for option_name, option in feature.options.items():
            values = ", ".join(option.values)
            lines.extend(
                [
                    f"   * - ``{option_name}``",
                    f"     - ``{values}``",
                    f"     - ``{option.default}``",
                    f"     - ``{option.cmake_variable}``",
                ]
            )
        lines.append("")
    return "\n".join(lines)


class FeatureMatrixDirective(Directive):
    """Insert registry-derived feature and option tables."""

    has_content = False

    def run(self) -> list[nodes.Node]:
        self.state.document.settings.env.note_dependency(str(registry_path()))
        container = nodes.container()
        content = StringList(
            _render_reference().splitlines(),
            source="tula_cmake feature registry",
        )
        self.state.nested_parse(content, self.content_offset, container)
        return [container]


def setup(app: Sphinx) -> dict[str, object]:
    """Register the feature-matrix directive."""
    app.add_directive("tula-feature-matrix", FeatureMatrixDirective)
    return {
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
