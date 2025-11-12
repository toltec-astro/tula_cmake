# tula_deps.cmake - User-facing API for lazy package loading
#
# Provides tula_deps_add() function for on-demand dependency loading

include_guard(GLOBAL)

# Include existing utilities
include(${CMAKE_CURRENT_LIST_DIR}/utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/utils/verbose_message.cmake)

#[=======================================================================[
@brief Add a tula package dependency to a variable (lazy evaluation)

This is the primary user-facing API for loading tula dependencies.
It only calls the package setup function when the target doesn't exist,
providing true lazy evaluation.

@param VAR_NAME Name of variable to append target to
@param PACKAGE_NAME Name of package (must match tula_setup_<PACKAGE_NAME> function)

Usage:
    set(my_deps "")
    tula_deps_add(my_deps Eigen3)
    tula_deps_add(my_deps Yaml)
    target_link_libraries(myapp PRIVATE ${my_deps})

]=======================================================================]
function(tula_deps_add VAR_NAME PACKAGE_NAME)
    # Check if setup function exists (should be defined by toolchain)
    if(NOT COMMAND tula_setup_${PACKAGE_NAME})
        message(FATAL_ERROR 
            "Package ${PACKAGE_NAME} not available.\n"
            "  Possible causes:\n"
            "  - Package not included in toolchain generation\n"
            "  - Package cmake file not loaded from toolchain\n"
            "  - Package name mismatch (check spelling)\n"
            "  Make sure you run 'conan install' to generate toolchain first."
        )
    endif()
    
    # Lazy evaluation: only call setup if target doesn't exist
    if(NOT TARGET tula::${PACKAGE_NAME})
        # Get mode from variable set by toolchain
        # Format: <PACKAGENAME>_MODE (e.g., EIGEN3_MODE, YAML_MODE)
        string(TOUPPER ${PACKAGE_NAME} _pkg_upper)
        set(_mode_var "${_pkg_upper}_MODE")
        
        if(NOT DEFINED ${_mode_var})
            message(FATAL_ERROR 
                "Mode not set for ${PACKAGE_NAME}.\n"
                "  Expected variable: ${_mode_var}\n"
                "  This should be set by the Conan toolchain.\n"
                "  Check that the package is enabled in conanfile.py options."
            )
        endif()
        
        set(_mode "${${_mode_var}}")
        verbose_message("Loading ${PACKAGE_NAME} in ${_mode} mode")
        
        # Call the package setup function with mode parameter
        # Use cmake_language(CALL) for dynamic function names (CMake 3.18+)
        cmake_language(CALL tula_setup_${PACKAGE_NAME} ${_mode})
    else()
        verbose_message("${PACKAGE_NAME} already loaded, reusing target")
    endif()
    
    # Verify target was created
    if(NOT TARGET tula::${PACKAGE_NAME})
        message(FATAL_ERROR 
            "Failed to create tula::${PACKAGE_NAME} target.\n"
            "  Setup function: tula_setup_${PACKAGE_NAME}\n"
            "  Mode: ${_mode}\n"
            "  Check the package cmake file for errors."
        )
    endif()
    
    # Append to list variable
    list(APPEND ${VAR_NAME} tula::${PACKAGE_NAME})
    
    # Return updated list to parent scope
    set(${VAR_NAME} ${${VAR_NAME}} PARENT_SCOPE)
    
    verbose_message("Added tula::${PACKAGE_NAME} to ${VAR_NAME}")
endfunction()

