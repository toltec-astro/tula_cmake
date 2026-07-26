from __future__ import annotations

from typing import Any, ClassVar

import pytest

from tula_cmake.recipe import TulaConan


class Options:
    def __init__(self) -> None:
        self.values: dict[str, object] = {}
        self.defaults: dict[str, object] = {}

    def update(
        self,
        values: dict[str, object],
        defaults: dict[str, object],
    ) -> None:
        self.values.update(values)
        self.defaults.update(defaults)


class Recipe:
    settings: tuple[str, ...] = ()
    options = Options()
    tula_default_options: ClassVar[dict[str, str]] = {
        "logging": "conan",
        "eigen": "system",
    }
    tula_public_features = ("logging",)


def test_project_can_override_registry_defaults() -> None:
    recipe = Recipe()
    TulaConan.init(recipe)

    assert recipe.options.defaults["logging"] == "conan"
    assert recipe.options.defaults["eigen"] == "system"
    assert recipe.options.defaults["yaml_cpp"] == "disabled"


def test_unknown_project_default_is_rejected() -> None:
    class InvalidRecipe(Recipe):
        tula_default_options: ClassVar[dict[str, str]] = {"typo": "system"}

    with pytest.raises(ValueError, match="unknown Tula default option"):
        TulaConan.init(InvalidRecipe())


def test_unknown_public_feature_is_rejected() -> None:
    class InvalidRecipe(Recipe):
        tula_public_features = ("typo",)

    recipe: Any = InvalidRecipe()
    recipe.output = type("Output", (), {"info": lambda *_: None})()
    recipe.requires = lambda *_args, **_kwargs: None
    recipe._providers = dict

    with pytest.raises(ValueError, match="unknown public Tula feature"):
        TulaConan.requirements(recipe)
