from __future__ import annotations

from pathlib import Path

import pytest

from tula_cmake.models import FeatureMode
from tula_cmake.registry import load_registry

from .feature_matrix.catalog import load_catalog

MATRIX_ROOT = Path(__file__).parent / "feature_matrix"


def test_matrix_catalog_covers_every_feature_mode_and_option_value() -> None:
    registry = load_registry()
    catalog = load_catalog(MATRIX_ROOT / "matrix.yaml")
    cases = catalog.cases(registry)

    for feature_name, feature in registry.features.items():
        probe = MATRIX_ROOT / "probes" / catalog.features[feature_name].probe
        assert probe.is_file()
        feature_cases = [case for case in cases if case.feature == feature_name]
        assert {case.mode for case in feature_cases}.issuperset(
            {FeatureMode.DISABLED, *feature.modes}
        )
        for option_name, option in feature.options.items():
            covered = {
                case.options[option_name]
                for case in feature_cases
                if f"--{option_name}--" in case.id
            }
            assert covered == set(option.values)


def test_matrix_catalog_rejects_a_missing_option_axis(tmp_path: Path) -> None:
    catalog_path = tmp_path / "matrix.yaml"
    catalog_path.write_text(
        """
schema_version: 1
features:
  logging:
    probe: logging.cpp
    option_axes: {}
  yaml_cpp:
    probe: yaml_cpp.cpp
  csv_parser:
    probe: csv_parser.cpp
  netcdf_c:
    probe: netcdf_c.cpp
  netcdf_cxx4:
    probe: netcdf_cxx4.cpp
    dependencies:
      netcdf_c: system
  bitmask:
    probe: bitmask.cpp
  meta_enum:
    probe: meta_enum.cpp
  clipp:
    probe: clipp.cpp
  perflibs:
    probe: perflibs.cpp
    option_axes: {}
  eigen:
    probe: eigen.cpp
    dependencies:
      perflibs: system
    option_axes: {}
  spectra:
    probe: spectra.cpp
    dependencies:
      perflibs: system
      eigen: conan
  boost:
    probe: boost.cpp
  fftw:
    probe: fftw.cpp
  ccfits:
    probe: ccfits.cpp
  ceres:
    probe: ceres.cpp
    dependencies:
      perflibs: system
      eigen: conan
  grppi:
    probe: grppi.cpp
    dependencies:
      logging: conan
      bitmask: cpm
      meta_enum: cpm
      perflibs: system
"""
    )
    catalog = load_catalog(catalog_path)
    with pytest.raises(ValueError, match="option axes"):
        catalog.validate_for(load_registry())
