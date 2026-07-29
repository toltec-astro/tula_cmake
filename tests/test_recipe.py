from __future__ import annotations

from typing import Any, ClassVar

import pytest

from tula_cmake.models import FeatureMode
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


def test_public_system_link_metadata_is_propagated(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    class SystemRecipe:
        tula_public_features = ("netcdf_c", "netcdf_cxx4")
        cpp_info = type(
            "CppInfo",
            (),
            {"includedirs": [], "system_libs": [], "libdirs": []},
        )()

        @staticmethod
        def _providers() -> dict[str, object]:
            return {
                "netcdf_c": "system",
                "netcdf_cxx4": "system",
            }

    recipe: Any = SystemRecipe()
    recipe._providers = lambda: {
        name: FeatureMode(mode) for name, mode in SystemRecipe._providers().items()
    }
    outputs = {
        ("nc-config", "--libs"): "-L/opt/netcdf/lib -lnetcdf",
        (
            "ncxx4-config",
            "--libs",
        ): "-L/opt/netcdf-cxx/lib -lnetcdf-cxx4 -lnetcdf",
        ("nc-config", "--includedir"): "/opt/netcdf/include",
        ("ncxx4-config", "--includedir"): "/opt/netcdf-cxx/include",
    }
    monkeypatch.setattr(
        "tula_cmake.recipe.subprocess.check_output",
        lambda command, **_kwargs: outputs[tuple(command)],
    )
    TulaConan.package_info(recipe)

    assert recipe.cpp_info.system_libs == ["netcdf", "netcdf-cxx4"]
    assert recipe.cpp_info.libdirs == [
        "/opt/netcdf/lib",
        "/opt/netcdf-cxx/lib",
    ]
    assert recipe.cpp_info.includedirs == [
        "/opt/netcdf/include",
        "/opt/netcdf-cxx/include",
    ]


def test_required_macos_openmp_metadata_uses_homebrew_libomp(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    class MacRecipe:
        settings = type("Settings", (), {"os": "Macos"})()
        cpp_info = type(
            "CppInfo",
            (),
            {
                "includedirs": [],
                "libdirs": [],
                "system_libs": [],
                "cxxflags": [],
                "sharedlinkflags": [],
                "exelinkflags": [],
            },
        )()

    recipe: Any = MacRecipe()
    monkeypatch.delenv("OPENMP_ROOT", raising=False)
    monkeypatch.setattr("tula_cmake.recipe.shutil.which", lambda _: "/opt/brew")
    monkeypatch.setattr(
        "tula_cmake.recipe.subprocess.check_output",
        lambda *_args, **_kwargs: "/opt/homebrew/opt/libomp\n",
    )

    TulaConan._propagate_required_openmp(recipe)

    assert recipe.cpp_info.includedirs == ["/opt/homebrew/opt/libomp/include"]
    assert recipe.cpp_info.libdirs == ["/opt/homebrew/opt/libomp/lib"]
    assert recipe.cpp_info.system_libs == ["omp"]
    assert recipe.cpp_info.cxxflags == ["-fopenmp"]
    assert recipe.cpp_info.sharedlinkflags == ["-fopenmp"]
    assert recipe.cpp_info.exelinkflags == ["-fopenmp"]
