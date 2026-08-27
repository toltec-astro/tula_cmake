"""Compare TulaCMake acceptance policy with packaged deployment profiles."""

from __future__ import annotations

import argparse
from copy import deepcopy
from pathlib import Path
from typing import Any

import yaml


PROFILE_PAIRS = {
    "development/gcc14": "development/linux-gcc14",
    "development/llvm20": "development/linux-llvm20",
    "snapshot/unity/gcc14": "release/2026.08-rc1/unity-gcc14",
    "snapshot/unity/llvm20": "release/2026.08-rc1/unity-llvm20",
}


def _load_spack(path: Path) -> dict[str, Any]:
    document = yaml.safe_load(path.read_text())
    if not isinstance(document, dict) or not isinstance(document.get("spack"), dict):
        msg = f"{path} does not contain a Spack environment"
        raise ValueError(msg)
    return document["spack"]


def _portable_policy(spack: dict[str, Any]) -> dict[str, Any]:
    """Remove checkout-local composition while retaining shared policy."""
    policy = deepcopy(spack)
    policy.pop("include", None)
    policy.pop("develop", None)
    packages = policy.get("packages")
    if isinstance(packages, dict):
        policy["packages"] = {"cxx": packages["cxx"]}
    return policy


def check_profiles(tula_cmake_root: Path, deploy_root: Path) -> None:
    acceptance = tula_cmake_root / "environments" / "acceptance"
    packaged = deploy_root / "src" / "tolteca_deploy" / "data" / "spack"
    mismatches: list[str] = []
    for acceptance_name, packaged_name in PROFILE_PAIRS.items():
        acceptance_path = acceptance / acceptance_name / "spack.yaml"
        if packaged_name.startswith("release/"):
            _, release_id, profile = packaged_name.split("/", maxsplit=2)
            packaged_path = (
                packaged
                / "releases"
                / release_id
                / "profiles"
                / profile
                / "spack.yaml"
            )
        else:
            packaged_path = packaged / "profiles" / packaged_name / "spack.yaml"
        acceptance_policy = _portable_policy(_load_spack(acceptance_path))
        packaged_policy = _portable_policy(_load_spack(packaged_path))
        if acceptance_policy != packaged_policy:
            mismatches.append(f"{acceptance_name} != {packaged_name}")
        else:
            print(f"aligned: {acceptance_name} -> {packaged_name}")
    if mismatches:
        msg = "Deployment profile drift:\n" + "\n".join(mismatches)
        raise ValueError(msg)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tula-cmake-root", type=Path, required=True)
    parser.add_argument("--deploy-root", type=Path, required=True)
    args = parser.parse_args()
    check_profiles(args.tula_cmake_root.resolve(), args.deploy_root.resolve())


if __name__ == "__main__":
    main()
