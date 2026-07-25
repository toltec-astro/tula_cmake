"""Sphinx configuration for tula-cmake."""

from __future__ import annotations

import tula_cmake

project = "tula-cmake"
author = "TolTEC developers"
copyright = "2026, TolTEC developers"
version = ".".join(tula_cmake.__version__.split(".")[:2])
release = tula_cmake.__version__

extensions = [
    "myst_parser",
    "sphinx.ext.autodoc",
    "sphinx.ext.napoleon",
    "sphinx.ext.viewcode",
    "sphinx_copybutton",
    "sphinxcontrib.autodoc_pydantic",
    "sphinxcontrib.typer",
]
autodoc_member_order = "bysource"
autodoc_typehints = "description"
autodoc_pydantic_model_show_json = True
autodoc_pydantic_model_show_config_summary = False
autodoc_pydantic_model_show_field_summary = True
autodoc_pydantic_model_show_validator_members = True
autodoc_pydantic_model_show_validator_summary = True
# The constrained-string regexes contain reStructuredText-significant
# characters. Field descriptions and JSON schemas retain the constraints
# without rendering those regexes as malformed inline links.
autodoc_pydantic_field_show_constraints = False

html_theme = "sphinx_book_theme"
html_title = f"{project} {release}"
exclude_patterns = ["_build"]
source_suffix = {
    ".rst": "restructuredtext",
    ".md": "markdown",
}

# Ensure autodoc imports the installed workspace package.
assert tula_cmake.__doc__
