"""
tula_conan.py - Base class for Conan-centric dependency management

This module provides TulaConan, a base ConanFile class that:
1. Discovers package definitions from targets/*.py files
2. Generates Conan options dynamically
3. Adds requirements based on mode selection (AUTO/CONAN call requires())
4. Generates CMakeToolchain with per-package configuration blocks

Key Design:
- Stateless: Each package function receives mode as parameter
- Lazy: Toolchain only defines functions, doesn't call them
- Profile-driven: All configuration via Conan profiles
"""

import importlib.util
import sys
from pathlib import Path
from typing import Dict, Any, List

from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMakeDeps
from conan.tools.cmake.toolchain.blocks import Block

# Global package registry (populated at module load)
_PACKAGE_REGISTRY: Dict[str, Dict[str, Any]] = {}


def _load_package_registry():
    """
    Discover and load all package definitions from targets/*.py files.
    
    Each package file must define:
    - PACKAGE_INFO: dict with name, modes, conan_requires, cmake_file
    - Optional: cmake_vars dict or callable for package-specific CMake variables
    """
    # Find targets directory relative to this file
    tula_cmake_dir = Path(__file__).parent
    targets_dir = tula_cmake_dir / "targets"
    
    if not targets_dir.exists():
        print(f"Warning: targets directory not found: {targets_dir}")
        return
    
    # Scan for .py files (excluding __init__.py and this file)
    for py_file in targets_dir.glob("*.py"):
        if py_file.name in ("__init__.py", "tula_conan.py"):
            continue
        
        package_name = py_file.stem
        
        try:
            # Import the module
            spec = importlib.util.spec_from_file_location(package_name, py_file)
            if spec is None or spec.loader is None:
                print(f"Warning: Cannot load spec for {py_file}")
                continue
            
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            
            # Validate required attributes
            if not hasattr(module, "PACKAGE_INFO"):
                print(f"Warning: {py_file} missing PACKAGE_INFO, skipping")
                continue
            
            package_info = module.PACKAGE_INFO
            
            # Validate PACKAGE_INFO structure
            required_keys = ["name", "modes", "conan_requires", "cmake_file"]
            missing_keys = [k for k in required_keys if k not in package_info]
            if missing_keys:
                print(f"Warning: {py_file} PACKAGE_INFO missing keys: {missing_keys}, skipping")
                continue
            
            # Verify cmake file exists
            cmake_file = targets_dir / package_info["cmake_file"]
            if not cmake_file.exists():
                print(f"Warning: {py_file} references non-existent cmake file: {cmake_file}, skipping")
                continue
            
            # Register package
            _PACKAGE_REGISTRY[package_info["name"]] = {
                "info": package_info,
                "cmake_file": cmake_file,
                "py_file": py_file,
            }
            
            print(f"Registered package: {package_info['name']}")
        
        except Exception as e:
            print(f"Error loading {py_file}: {e}")
            continue


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
    
    # Standard Conan settings
    settings = "os", "compiler", "build_type", "arch"
    
    # Generate options from package registry (class-level, not property)
    # This must be a dict, not a property, for Conan to work
    options = {name: pkg["info"]["modes"] for name, pkg in _PACKAGE_REGISTRY.items()}
    default_options = {name: "DISABLED" for name in _PACKAGE_REGISTRY.keys()}
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        # Infer name and version if not set
        if not hasattr(self, 'name') or self.name is None:
            self.set_name()
        
        if not hasattr(self, 'version') or self.version is None:
            self.set_version()
    
    def set_name(self):
        """Infer package name from directory name."""
        self.name = Path(self.recipe_folder).name
        print(f"Inferred package name: {self.name}")
    
    def set_version(self):
        """Read version from VERSION file or use default."""
        version_file = Path(self.recipe_folder) / "VERSION"
        if version_file.exists():
            self.version = version_file.read_text().strip()
            print(f"Read version from VERSION file: {self.version}")
        else:
            self.version = "0.0.0"
            print(f"No VERSION file, using default: {self.version}")
    
    def requirements(self):
        """
        Add Conan requirements for enabled packages.
        
        Key design: Both AUTO and CONAN modes call requires().
        The difference is handled in CMake:
        - CONAN: Fails if Conan package unavailable
        - AUTO: Falls back to CPM/SYSTEM if Conan fails
        """
        for name, pkg in _PACKAGE_REGISTRY.items():
            # Use getattr to access option value (Conan converts dict to Options object)
            mode = str(getattr(self.options, name, "DISABLED"))
            
            # Both AUTO and CONAN call requires() - difference is in CMake fallback
            if mode in ("AUTO", "CONAN"):
                for req in pkg["info"]["conan_requires"]:
                    self.output.info(f"Adding requirement for {name}: {req} (mode={mode})")
                    self.requires(req)
            else:
                self.output.info(f"Skipping Conan requirement for {name} (mode={mode})")
    
    def generate(self):
        """
        Generate CMake integration files.
        
        Creates:
        1. CMakeDeps - Standard Conan find_package() files
        2. CMakeToolchain - With per-package configuration blocks
        """
        try:
            # Generate CMakeDeps for find_package() support
            self.output.info("Generating CMakeDeps...")
            deps = CMakeDeps(self)
            deps.generate()
            self.output.info("CMakeDeps generated successfully")
            
            # Generate CMakeToolchain with package blocks
            self.output.info("Creating CMakeToolchain...")
            tc = CMakeToolchain(self)
            
            # Standard configuration
            self.output.info("Setting cache variables...")
            tc.cache_variables["CMAKE_BUILD_TYPE"] = str(self.settings.build_type)
            tc.cache_variables["CMAKE_CXX_STANDARD"] = str(self.settings.compiler.cppstd)
            tc.cache_variables["CMAKE_CXX_EXTENSIONS"] = "OFF"
            tc.cache_variables["CMAKE_CXX_STANDARD_REQUIRED"] = "ON"
            
            # Disable Conan's CMake presets - we have our own
            self.output.info("Disabling CMake presets...")
            tc.user_presets_path = False
            
            # Add utility includes (must be first)
            self.output.info("Adding utilities block...")
            self._add_utils_block(tc)
            
            # Add per-package blocks (only for enabled packages)
            self.output.info("Adding package blocks...")
            self._add_package_blocks(tc)
            
            # Generate the toolchain file
            self.output.info("Generating toolchain file...")
            tc.generate()
            
            self.output.success("Generated CMake toolchain with package blocks")
        except Exception as e:
            self.output.error(f"Error in generate(): {e}")
            import traceback
            self.output.error(traceback.format_exc())
            raise
    
    def _add_utils_block(self, tc: CMakeToolchain):
        """
        Add utility includes and setup to toolchain.
        
        This block:
        1. Sets up CMAKE_MODULE_PATH for tula utilities
        2. Includes tula_sensible.cmake for build environment setup
        3. Includes tula_deps.cmake for the dependency API
        """
        tula_cmake_dir = Path(__file__).parent
        tula_sensible_file = tula_cmake_dir / "tula_sensible.cmake"
        tula_deps_file = tula_cmake_dir / "tula_deps.cmake"
        utils_dir = tula_cmake_dir / "utils"
        
        # Create a Block subclass for utilities
        class TulaUtilsBlock(Block):
            @property
            def template(self):
                return f'''
########## 'tula_setup' block #############
# tula build environment and dependency management

# Add tula utilities to module path
list(PREPEND CMAKE_MODULE_PATH "{utils_dir}")

# Include sensible defaults and checks
include("{tula_sensible_file}")

# Include dependency management API
include("{tula_deps_file}")
'''
        
        tc.blocks["tula_setup"] = TulaUtilsBlock
        self.output.info("Added tula setup block (sensible defaults + deps API)")
    
    def _add_package_blocks(self, tc: CMakeToolchain):
        """
        Create CMake blocks for ALL packages in the registry.
        
        CRITICAL DESIGN: 
        - Generate blocks for ALL packages, not just enabled ones
        - Each block includes the package .cmake file and sets variables
        - Blocks only DEFINE functions, they DON'T CALL them
        - Functions are called lazily by user via tula_deps_add()
        
        This ensures consistent behavior whether packages come from:
        - Conan (mode=CONAN/AUTO with requires())
        - CPM (mode=CPM, source fetch)
        - System (mode=SYSTEM, find_package())
        """
        for name, pkg in _PACKAGE_REGISTRY.items():
            # Use getattr to access option value (Conan converts dict to Options object)
            mode = str(getattr(self.options, name, "DISABLED"))
            
            # Generate package-specific CMake variables
            cmake_vars = self._generate_package_vars(name, mode, pkg)
            
            # Create the CMake block template (includes ALL packages)
            block_template = self._create_package_block(name, mode, cmake_vars, pkg)
            
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
            
            self.output.info(f"Added block for {name} (mode={mode})")
    
    def _generate_package_vars(self, name: str, mode: str, pkg: Dict[str, Any]) -> Dict[str, Any]:
        """
        Generate CMake variables for a package.
        Gets package-specific variables and adds MODE.
        """
        try:
            # Get package-specific cmake_vars (can be dict or callable)
            cmake_vars_def = pkg["info"].get("cmake_vars", {})
            
            if callable(cmake_vars_def):
                # Support callable for complex cases
                result = cmake_vars_def(self, mode)
                cmake_vars = dict(result) if isinstance(result, dict) else {}
            else:
                # Simple dict copy
                cmake_vars = dict(cmake_vars_def) if isinstance(cmake_vars_def, dict) else {}
            
            # Always add MODE
            cmake_vars["MODE"] = mode
            return cmake_vars
        except Exception as e:
            self.output.warning(f"Error generating cmake vars for {name}: {e}")
            return {"MODE": mode}
    
    def _create_package_block(self, name: str, mode: str, vars_dict: Dict[str, Any], 
                              pkg: Dict[str, Any]) -> str:
        """
        Create CMake block content for a package.
        
        Block structure:
        1. Set package mode variable
        2. Set package-specific variables
        3. Include package cmake file
        4. DO NOT call setup function (lazy evaluation)
        """
        lines = [
            f"# Package: {name} (mode={mode})",
            "",
        ]
        
        # Package name in uppercase for variable prefixes
        pkg_upper = name.upper()
        
        # Set all variables with package prefix
        for var_name, var_value in vars_dict.items():
            # Handle list variables
            if isinstance(var_value, list):
                # Join list items with semicolon (CMake list separator)
                var_value_str = ";".join(str(v) for v in var_value)
                lines.append(f'set({pkg_upper}_{var_name} "{var_value_str}")')
            else:
                lines.append(f'set({pkg_upper}_{var_name} "{var_value}")')
        
        lines.append("")
        
        # Include the package cmake file (defines tula_setup_<name> function)
        cmake_file = pkg["cmake_file"]
        lines.append(f'include("{cmake_file}")')
        
        lines.append("")
        lines.append(f"# Note: tula_setup_{name}() will be called lazily by tula_deps_add()")
        lines.append("")
        
        return "\n".join(lines)


def get_package_registry() -> Dict[str, Dict[str, Any]]:
    """
    Get the global package registry.
    Useful for debugging or introspection.
    """
    return _PACKAGE_REGISTRY


def list_available_packages() -> List[str]:
    """List all registered package names."""
    return list(_PACKAGE_REGISTRY.keys())

