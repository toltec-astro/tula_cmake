"""Validate local include paths referenced by checked-in Spack environments."""

from __future__ import annotations

import argparse
from pathlib import Path

import yaml


def _include_path(item: object) -> str:
    if isinstance(item, str):
        return item
    if isinstance(item, dict) and isinstance(item.get("path"), str):
        return item["path"]
    msg = f"unsupported Spack include entry: {item!r}"
    raise ValueError(msg)


def check_manifests(root: Path) -> None:
    """Require every repository-owned Spack include to resolve locally."""
    manifests = sorted((root / "environments").rglob("spack.yaml"))
    if not manifests:
        raise ValueError(f"no Spack environments found below {root}")

    checked = 0
    missing: list[str] = []
    for manifest in manifests:
        document = yaml.safe_load(manifest.read_text())
        spack = document.get("spack") if isinstance(document, dict) else None
        if not isinstance(spack, dict):
            missing.append(f"{manifest}: missing top-level spack mapping")
            continue

        for item in spack.get("include", []):
            reference = _include_path(item)
            if "://" in reference or "$" in reference:
                continue
            checked += 1
            target = Path(reference)
            if not target.is_absolute():
                target = manifest.parent / target
            if not target.exists():
                missing.append(f"{manifest}: {reference}")

    if missing:
        msg = "Broken Spack manifest paths:\n" + "\n".join(missing)
        raise ValueError(msg)
    print(f"validated {checked} includes in {len(manifests)} Spack environments")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    args = parser.parse_args()
    check_manifests(args.root.resolve())


if __name__ == "__main__":
    main()
