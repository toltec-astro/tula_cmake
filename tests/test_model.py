from pathlib import Path
from tempfile import TemporaryDirectory
from unittest import TestCase

from tula_cmake import profiles_dir
from tula_cmake.model import (
    FeatureMode,
    load_feature_registry,
    render_cmake_manifest,
    validate_selection,
)


class FeatureRegistryTests(TestCase):
    def test_logging_supports_all_four_user_modes(self) -> None:
        registry = load_feature_registry()
        self.assertEqual(
            registry["logging"].option_values,
            ("disabled", "conan", "cpm", "system"),
        )

    def test_manifest_records_disabled_without_provider_work(self) -> None:
        registry = load_feature_registry()
        manifest = render_cmake_manifest(
            registry,
            {"logging": FeatureMode.DISABLED},
            logging_level="info",
        )
        self.assertIn('set(TULA_FEATURE_logging_MODE "disabled")', manifest)
        self.assertIn('set(TULA_LOGGING_LEVEL "info")', manifest)

    def test_bundled_profile_is_discoverable(self) -> None:
        self.assertTrue((profiles_dir() / "linux-clang20-debug").is_file())

    def test_conan_mode_requires_a_requirement(self) -> None:
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "cmake").mkdir()
            (root / "cmake" / "Demo.cmake").write_text("")
            registry = root / "features.yaml"
            registry.write_text(
                "Demo:\n  modes: [conan]\n  conan_requires: []\n  cmake_module: Demo.cmake\n"
            )
            with self.assertRaisesRegex(ValueError, "requires conan_requires"):
                load_feature_registry(registry)

    def test_disabled_dependency_is_rejected(self) -> None:
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "cmake").mkdir()
            (root / "cmake" / "Feature.cmake").write_text("")
            registry_file = root / "features.yaml"
            registry_file.write_text(
                "base:\n"
                "  modes: [system]\n"
                "  cmake_module: Feature.cmake\n"
                "feature:\n"
                "  modes: [system]\n"
                "  dependencies: [base]\n"
                "  cmake_module: Feature.cmake\n"
            )
            registry = load_feature_registry(registry_file)
            with self.assertRaisesRegex(ValueError, "requires enabled feature base"):
                validate_selection(
                    registry,
                    {
                        "base": FeatureMode.DISABLED,
                        "feature": FeatureMode.SYSTEM,
                    },
                )
