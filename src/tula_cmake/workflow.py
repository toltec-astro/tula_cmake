"""One-command source-graph, external-provider, and CMake workflow."""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from collections.abc import Callable, Sequence
from pathlib import Path

from .models import BuildRequest, GeneratedPresets, UserPresets
from .registry import cmake_cache_variables, load_registry, render_manifest
from .resources import infrastructure_dir, profiles_dir
from .superbuild import (
    PROJECT_MANIFEST_NAME,
    ProjectGraphResolver,
    parse_provider_overrides,
    render_conanfile,
    render_project_manifest,
)

CommandRunner = Callable[[Sequence[str], Path | None], None]


def run_command(command: Sequence[str], cwd: Path | None = None) -> None:
    """Run one external command and fail on a non-zero exit status."""
    subprocess.run(tuple(command), cwd=cwd, check=True)


def conan_command() -> tuple[str, ...]:
    """Return the Conan entry point from this environment or ``PATH``."""
    environment_entry_point = Path(sys.executable).with_name("conan")
    if environment_entry_point.is_file():
        return (str(environment_entry_point),)
    executable = shutil.which("conan")
    if executable:
        return (executable,)
    raise FileNotFoundError("Conan entry point is not installed")


class BuildWorkflow:
    """Coordinate graph resolution, Conan externals, and CMake presets."""

    def __init__(
        self,
        request: BuildRequest,
        *,
        runner: CommandRunner = run_command,
    ) -> None:
        self.request = request
        self._run = runner

    def execute(self) -> None:
        """Run the complete build workflow."""
        source = self.request.source.resolve()
        output = (
            self.request.output.resolve()
            if self.request.output.is_absolute()
            else (source / self.request.output).resolve()
        )
        if self.request.config_source:
            self._phase(
                f"bootstrap: install Conan configuration from "
                f"{self.request.config_source}"
            )
            self._run(
                (
                    *conan_command(),
                    "config",
                    "install",
                    self.request.config_source,
                ),
                None,
            )
        if (source / PROJECT_MANIFEST_NAME).is_file():
            self._execute_superbuild(source, output)
            return
        self._execute_legacy_package(source, output)

    def _execute_legacy_package(self, source: Path, output: Path) -> None:
        """Run the retained package-first workflow during the migration."""
        profiles = self.request.profiles or (str(self._default_profile()),)

        install = [
            *conan_command(),
            "install",
            str(source),
            "--output-folder",
            str(output),
            f"--build={self.request.build_policy}",
        ]
        for profile in profiles:
            install.extend(("--profile:all", profile))
        for option in self.request.options:
            install.extend(("--options:host", f"&:{option}"))
        self._phase("conan: resolve the package graph and generate build files")
        self._run(install, None)

        preset = self.request.preset or self._generated_preset(source)
        self._phase(f"cmake: configure with preset {preset}")
        self._run(("cmake", "--preset", preset, "--fresh"), source)
        self._phase(f"cmake: build with preset {preset}")
        self._run(("cmake", "--build", "--preset", preset), source)

    def _execute_superbuild(self, source: Path, output: Path) -> None:
        """Resolve and build one recursive source-superbuild graph."""
        registry = load_registry()
        overrides = parse_provider_overrides(self.request.providers)
        self._phase("graph: resolve recursive project manifests and providers")
        graph = ProjectGraphResolver(registry).resolve(source, overrides)

        generated = output / "generated"
        generators = output / "generators"
        generated.mkdir(parents=True, exist_ok=True)
        generators.mkdir(parents=True, exist_ok=True)
        feature_manifest = generated / "tula_features.cmake"
        project_manifest = generated / "tula_projects.cmake"
        conanfile = generated / "conanfile.txt"
        feature_manifest.write_text(render_manifest(registry, graph.providers))
        project_manifest.write_text(render_project_manifest(graph))
        conanfile.write_text(render_conanfile(graph.conan_requires))

        profiles = self.request.profiles or (str(self._default_profile()),)
        install = [
            *conan_command(),
            "install",
            str(conanfile),
            "--output-folder",
            str(generators),
            f"--build={self.request.build_policy}",
        ]
        for profile in profiles:
            install.extend(("--profile:all", profile))
        for option in self.request.options:
            install.extend(("--options:host", option))
        requirements = ", ".join(graph.conan_requires) or "none"
        self._phase(
            f"conan: materialize selected external requirements ({requirements})"
        )
        self._run(install, None)

        option_values = {
            name: option.default
            for feature in registry.features.values()
            for name, option in feature.options.items()
        }
        cache_variables = cmake_cache_variables(
            registry,
            graph.providers,
            option_values,
        )
        cache_variables.update(
            {
                "CMAKE_PROJECT_TOP_LEVEL_INCLUDES": str(
                    infrastructure_dir() / "TulaBootstrap.cmake"
                ),
                "TULA_FEATURE_MANIFEST": str(feature_manifest),
                "TULA_PROJECT_MANIFEST": str(project_manifest),
            }
        )
        preset = self._write_superbuild_presets(
            source,
            output,
            generators,
            cache_variables,
        )
        self._phase(f"cmake: configure recursive source graph with preset {preset}")
        self._run(("cmake", "--preset", preset, "--fresh"), source)
        self._phase(f"cmake: build recursive source graph with preset {preset}")
        self._run(("cmake", "--build", "--preset", preset), source)

    @staticmethod
    def _write_superbuild_presets(
        source: Path,
        output: Path,
        generators: Path,
        cache_variables: dict[str, str],
    ) -> str:
        """Adapt Conan's virtual-consumer presets for the actual root source."""
        generated_path = generators / "CMakePresets.json"
        if not generated_path.is_file():
            raise RuntimeError(f"Conan did not generate {generated_path}")
        document = json.loads(generated_path.read_text())
        configure_presets = document.get("configurePresets", [])
        build_presets = document.get("buildPresets", [])
        if not configure_presets or not build_presets:
            raise RuntimeError(f"{generated_path} contains no build presets")
        for configure in configure_presets:
            toolchain = Path(configure["toolchainFile"])
            if not toolchain.is_absolute():
                toolchain = generators / toolchain
            configure["toolchainFile"] = str(toolchain.resolve())
            configure["binaryDir"] = str((output / "build").resolve())
            configure.setdefault("cacheVariables", {}).update(cache_variables)
        document.setdefault("vendor", {})["tula_cmake"] = {"generated": True}

        user_path = source / "CMakeUserPresets.json"
        if user_path.is_file():
            existing = json.loads(user_path.read_text())
            generated_by_tula = (
                existing.get("vendor", {}).get("tula_cmake", {}).get("generated", False)
            )
            if not generated_by_tula:
                raise RuntimeError(f"refusing to replace user-owned {user_path}")
        user_path.write_text(json.dumps(document, indent=2) + "\n")
        return build_presets[0]["name"]

    @staticmethod
    def _phase(message: str) -> None:
        print(f"==> {message}", flush=True)

    @staticmethod
    def _generated_preset(source: Path) -> str:
        user_path = source / "CMakeUserPresets.json"
        if not user_path.is_file():
            raise RuntimeError(f"Conan did not generate {user_path}")
        user = UserPresets.model_validate_json(user_path.read_text())
        if not user.include:
            raise RuntimeError(f"{user_path} does not include Conan presets")
        generated_path = (source / user.include[0]).resolve()
        generated = GeneratedPresets.model_validate_json(generated_path.read_text())
        if not generated.buildPresets:
            raise RuntimeError(f"{generated_path} contains no build presets")
        return generated.buildPresets[0].name

    @staticmethod
    def _default_profile() -> Path:
        """Return the supported host profile for the current platform."""
        name = (
            "macos-brew-llvm-debug" if sys.platform == "darwin" else "linux-gcc13-debug"
        )
        return profiles_dir() / name
