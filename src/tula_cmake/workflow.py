"""One-command Conan and CMake workflow."""

from __future__ import annotations

import shutil
import subprocess
import sys
from collections.abc import Callable, Sequence
from pathlib import Path

from .models import BuildRequest, GeneratedPresets, UserPresets
from .resources import profiles_dir

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
    """Coordinate bootstrap, Conan generation, and CMake presets."""

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
        output = self.request.output.resolve()
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
