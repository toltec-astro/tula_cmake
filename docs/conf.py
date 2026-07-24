"""Sphinx configuration for tula-cmake."""

from __future__ import annotations

import tula_cmake

project = "tula-cmake"
author = "TolTEC developers"
copyright = "2026, TolTEC developers"
version = "3.1"
release = "3.1.0"

extensions = [
    "myst_parser",
    "sphinx.ext.autodoc",
    "sphinx.ext.napoleon",
    "sphinx.ext.viewcode",
    "sphinxcontrib.autodoc_pydantic",
    "sphinxcontrib.typer",
]
autodoc_member_order = "bysource"
autodoc_typehints = "description"
autodoc_pydantic_model_show_json = True
autodoc_pydantic_model_show_config_summary = False
autodoc_pydantic_model_show_validator_summary = True

html_theme = "sphinx_book_theme"
html_title = f"{project} {release}"
exclude_patterns = ["_build"]

# Ensure autodoc imports the installed workspace package.
assert tula_cmake.__doc__
