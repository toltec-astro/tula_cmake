"""
tula_conan.py - Base class for Conan-centric dependency management

This module provides TulaConan, a base ConanFile class that:
1. Discovers package definitions from targets/packages.yaml
2. Generates Conan options dynamically
3. Adds requirements based on mode selection (AUTO/CONAN call requires())
4. Generates CMakeToolchain with per-package configuration blocks

Key Design:
- Stateless: Each package function receives mode as parameter
- Lazy: Toolchain only defines functions, doesn't call them
- Profile-driven: All configuration via Conan profiles
- YAML-based: Package definitions in targets/packages.yaml
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum, auto
from pathlib import Path
from typing import Any, Callable, Self

import yaml
from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMakeDeps
from conan.tools.cmake.toolchain.blocks import Block


class PackageMode(StrEnum):
    """Valid modes for package dependency resolution."""
    AUTO = auto()      # Try CONAN, fallback to CPM/SYSTEM
    DISABLED = auto()  # Package not used
    CONAN = auto()     # Use Conan package (fail if unavailable)
    CPM = auto()       # Fetch from source via CPM
    SYSTEM = auto()    # Use system-installed package


@dataclass(frozen=True)
class PackageInfo:
    """Package definition loaded from packages.yaml."""
    name: str
    modes: tuple[PackageMode, ...]
    conan_requires: tuple[str, ...]
    cmake_vars: dict[str, Any]
    cmake_file: Path

    @classmethod
    def from_yaml(cls, name: str, data: dict[str, Any], targets_dir: Path) -> Self:
        """
        Create PackageInfo from YAML dict entry.
        
        Parameters
        ----------
        name
            Package name (key from YAML)
        data
            Package definition dict from YAML
        targets_dir
            Directory containing .cmake files
        """
        # Convert mode strings to enums, add AUTO and DISABLED
        yaml_modes = [PackageMode(m) for m in data.get("modes", [])]
        all_modes = (PackageMode.AUTO, PackageMode.DISABLED, *yaml_modes)
        
        return cls(
            name=name,
            modes=all_modes,
            conan_requires=tuple(data.get("conan_requires", [])),
            cmake_vars=dict(data.get("cmake_vars", {})),
            cmake_file=targets_dir / f"{name}.cmake",
        )

    @property
    def mode_values(self) -> list[str]:
        """Get mode string values for Conan options."""
        return [m.value for m in self.modes]


# Global package registry (populated at module load)
_PACKAGE_REGISTRY: dict[str, PackageInfo] = {}

# Single source of truth for all package definitions
_PACKAGES_FILE = Path(__file__).parent / "targets" / "packages.yaml"


def _load_package_registry():
    """
    Load all package definitions from targets/packages.yaml.
    
    The YAML file contains a dict where each key is a package name and value has:
    - modes: List of supported modes (subset of conan, cpm, system)
             AUTO and DISABLED are added automatically
    - conan_requires: List of Conan package requirements
    - cmake_vars: Optional dict of CMake variables for this package
    
    The cmake_file is auto-derived as {package_name}.cmake in the targets folder.
    """
    if not _PACKAGES_FILE.exists():
        raise FileNotFoundError(f"Package definitions not found: {_PACKAGES_FILE}")
    
    targets_dir = _PACKAGES_FILE.parent
    
    with open(_PACKAGES_FILE, 'r') as f:
        all_packages = yaml.safe_load(f)
    
    for name, data in all_packages.items():
        pkg = PackageInfo.from_yaml(name, data, targets_dir)
        _PACKAGE_REGISTRY[name] = pkg
        print(f"Registered package: {name} (modes: {pkg.modes})")


# Load registry at module import time
_load_package_registry()


class TulaConan(ConanFile):
    """
    Base class for tula_cmake Conan-centric dependency management.
    
    Subclass this in your conanfile.py:
    
        from tula_cmake.tula_conan import TulaConan
        
        class MyPackageConan(TulaConan):
            pass  # That's it!
    
    Or with custom additions:
    
        class MyPackageConan(TulaConan):
            def requirements(self):
                super().requirements()
                # Add package-specific requirements
                self.requires("mylib/1.0")
    """
    
    # Type hints for Conan attributes (set by Conan, declared here for Pylance)
    name: str | None = None
    version: str = "0.0.0"
    recipe_folder: str
    requires: Callable[[str], None]
    
    # Standard Conan settings
    settings = "os", "compiler", "build_type", "arch"
    
    # Generate options from package registry (class-level, not property)
    # This must be a dict, not a property, for Conan to work
    options = {name: pkg.mode_values for name, pkg in _PACKAGE_REGISTRY.items()}
    default_options = {name: PackageMode.DISABLED.value for name in _PACKAGE_REGISTRY}
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        # Infer name if not set by subclass
        if self.name is None:
            self.name = Path(self.recipe_folder).name
            print(f"Inferred package name: {self.name}")

    def layout(self):
        """Route Conan generators to build/<compiler><version>-<build_type_lower>/.

        This ensures 'conan install .' always generates into the same build
        subdirectory that CMakeUserPresets.json includes — no -of flag required.
        For example, clang 20 Debug → build/clang20-debug/.
        """
        compiler = str(self.settings.compiler).lower()
        if "clang" in compiler:
            compiler = "clang"
        version = str(self.settings.compiler.version)
        build_type = str(self.settings.build_type).lower()
        subdir = f"build/{compiler}{version}-{build_type}"
        self.folders.build = subdir
        self.folders.generators = subdir

    def _get_package_mode(self, package_name: str) -> PackageMode:
        """Get the resolved mode for a package from Conan options."""
        mode_str = str(getattr(self.options, package_name, PackageMode.DISABLED.value))
        return PackageMode(mode_str)
    
    def requirements(self):
        """
        Add Conan requirements for enabled packages.
        
        Key design: Both AUTO and CONAN modes call requires().
        The difference is handled in CMake:
        - CONAN: Fails if Conan package unavailable
        - AUTO: Falls back to CPM/SYSTEM if Conan fails
        """
        for name, pkg in _PACKAGE_REGISTRY.items():
            mode = self._get_package_mode(name)
            
            if mode in (PackageMode.AUTO, PackageMode.CONAN):
                for req in pkg.conan_requires:
                    self.output.info(f"Adding requirement for {name}: {req} (mode={mode.value})")
                    self.requires(req)
            else:
                self.output.info(f"Skipping Conan requirement for {name} (mode={mode.value})")
    
    def generate(self):
        """
        Generate CMake integration files.
        
        Creates:
        1. CMakeDeps - Standard Conan find_package() files
        2. CMakeToolchain - With per-package configuration blocks
        """
        # Generate CMakeDeps for find_package() support
        deps = CMakeDeps(self)
        deps.generate()
        
        # Generate CMakeToolchain with package blocks
        tc = CMakeToolchain(self)
        self._add_utils_block(tc)
        self._add_package_blocks(tc)
        self._add_tula_target_block(tc)
        tc.generate()
    
    def _add_utils_block(self, tc: CMakeToolchain):
        """
        Add utility includes and setup to toolchain.
        
        This block includes:
        1. tula_sensible.cmake - Sensible compiler defaults
        2. tula_deps.cmake - tula_deps_add() API for loading dependencies
        """
        tula_cmake_dir = Path(__file__).parent
        sensible_file = tula_cmake_dir / "tula_sensible.cmake"
        deps_file = tula_cmake_dir / "tula_deps.cmake"
        
        # Create a Block subclass for utilities
        class TulaUtilsBlock(Block):
            @property
            def template(self):
                return f'''
########## 'tula_setup' block #############
# tula build environment and dependency management

# Apply sensible compiler defaults (RPATH, warnings, etc.)
include("{sensible_file}")

# Include tula deps API (tula_deps_add function)
include("{deps_file}")
'''
        
        tc.blocks["tula_setup"] = TulaUtilsBlock
        self.output.info("Added tula setup block (sensible + deps API)")

    def _add_tula_target_block(self, tc: CMakeToolchain):
        """
        Add tula::headers and tula::tula INTERFACE targets to the toolchain.

        This allows downstream projects to simply write:
            target_link_libraries(mylib PUBLIC tula::tula)
        without needing add_subdirectory(tula).

        tula::headers  — tula include/ directory only
        tula::tula     — tula::headers + all enabled TULA_DEPS
        """
        # Locate the tula C++ headers.
        # tula_cmake/include/ is a symlink → ../include/ (i.e. tula/include/).
        # This works both in the source tree and when installed into a venv via pip
        # (setuptools follows the symlink and copies the headers into site-packages).
        tula_include = Path(__file__).parent / "include"
        if not tula_include.is_dir():
            # Fallback: tula_cmake is a subdir of tula (no symlink present)
            tula_include = Path(__file__).parent.parent / "include"

        class TulaTargetBlock(Block):
            @property
            def template(self):
                return f'''
########## 'tula_target' block #############
# Create tula::headers and tula::tula INTERFACE targets.
# This block runs after all package blocks, so TULA_DEPS is fully populated.
# Downstream projects link to tula::tula instead of add_subdirectory(tula).

if(NOT TARGET tula_headers)
    add_library(tula_headers INTERFACE)
    target_include_directories(tula_headers INTERFACE "{tula_include}")
    add_library(tula::headers ALIAS tula_headers)
endif()

if(NOT TARGET tula_all)
    add_library(tula_all INTERFACE)
    target_link_libraries(tula_all INTERFACE tula::headers ${{TULA_DEPS}})
    add_library(tula::tula ALIAS tula_all)
endif()
'''
        tc.blocks["tula_target"] = TulaTargetBlock
        self.output.info(f"Added tula target block (include: {tula_include})")

    def _add_package_blocks(self, tc: CMakeToolchain):
        """
        Create CMake blocks for enabled packages in the registry.
        
        For each enabled package (not DISABLED):
        1. Set package variables (<PKG>_MODE, <PKG>_CPM_URL, etc.)
        2. Include package cmake file (defines tula_<pkg>_add_* functions)
        3. Call tula_deps_add to load the package immediately
        
        Users don't need to do anything - packages are ready after toolchain.
        """
        for name, pkg in _PACKAGE_REGISTRY.items():
            mode = self._get_package_mode(name)
            
            if mode == PackageMode.DISABLED:
                self.output.info(f"Skipping block for {name} (mode=DISABLED)")
                continue
            
            # Generate package-specific CMake variables
            cmake_vars = self._generate_package_vars(mode, pkg)
            
            # Create the CMake block template (only for enabled packages)
            block_template = self._create_package_block(mode, cmake_vars, pkg)
            
            # Create a Block subclass with this template
            # IMPORTANT: Use default argument to capture value, not reference
            def make_block_class(template=block_template):
                class TulaPackageBlock(Block):
                    @property
                    def template(self):
                        return template
                return TulaPackageBlock
            
            # Add to toolchain with unique block name
            tc.blocks[f"tula_{name}"] = make_block_class()
            
            self.output.info(f"Added block for {name} (mode={mode.value})")
    
    def _generate_package_vars(self, mode: PackageMode, pkg: PackageInfo) -> dict[str, Any]:
        """
        Generate CMake variables for a package.
        Gets package-specific cmake_vars from YAML and adds MODE.
        """
        cmake_vars = dict(pkg.cmake_vars)
        cmake_vars["MODE"] = mode.value
        return cmake_vars
    
    def _create_package_block(self, mode: PackageMode, vars_dict: dict[str, Any], 
                              pkg: PackageInfo) -> str:
        """
        Create CMake block content for a package.
        
        Block structure:
        1. Set package variables (<PKG>_MODE, <PKG>_CPM_URL, etc.)
        2. Include package cmake file (defines tula_<pkg>_add_* functions)
        3. Call tula_deps_add to load the package
        """
        lines = [
            f"########## 'tula_{pkg.name}' block #############",
            f"# Package: {pkg.name} (mode={mode.value})",
            "",
        ]
        
        # Package name in uppercase for variable prefixes
        pkg_upper = pkg.name.upper()
        
        # Set all variables with TULA_<PKG>_ prefix
        for var_name, var_value in vars_dict.items():
            if isinstance(var_value, list):
                var_value_str = ";".join(str(v) for v in var_value)
                lines.append(f'set(TULA_{pkg_upper}_{var_name} "{var_value_str}")')
            else:
                lines.append(f'set(TULA_{pkg_upper}_{var_name} "{var_value}")')
        
        lines.append("")
        lines.append(f'include("{pkg.cmake_file}")')
        lines.append(f'tula_deps_add(TULA_DEPS {pkg.name})')
        lines.append("")
        
        return "\n".join(lines)


def get_package_registry() -> dict[str, PackageInfo]:
    """
    Get the global package registry.
    Useful for debugging or introspection.
    """
    return _PACKAGE_REGISTRY


def list_available_packages() -> list[str]:
    """List all registered package names."""
    return list(_PACKAGE_REGISTRY.keys())

