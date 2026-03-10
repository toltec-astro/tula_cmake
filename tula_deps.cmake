# tula_deps.cmake - Dependency loading API for tula projects
#
# Provides tula_deps_add() which dispatches to package-specific functions
# based on the MODE variable set by Conan toolchain.
#
# Each package cmake file defines:
#   tula_<Package>_add_conan() - Load from Conan
#   tula_<Package>_add_cpm()   - Fetch via CPM
#   tula_<Package>_add_system() - Use system find_package
#
# The toolchain calls tula_deps_add for each enabled package automatically.
# Users just link against ${TULA_DEPS} which contains all loaded targets.

include_guard(GLOBAL)

# Initialize TULA_DEPS as a cache variable to accumulate targets
set(TULA_DEPS "" CACHE INTERNAL "All loaded tula dependency targets")

# Packages that need CPM retry after project() enables CXX
set(TULA_DEFERRED_PKGS "" CACHE INTERNAL "Packages deferred from toolchain phase for post-project() CPM retry")

# Add utilities and cmake find modules to module path
list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/utils")
list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")
include(verbose_message)

#[=======================================================================[
@brief Add a tula package dependency

Dispatches to tula_<Package>_add_<mode>() based on <PKG>_MODE variable.
Appends tula::<Package> to VAR_NAME.

Called automatically by toolchain for enabled packages.
Users just use: target_link_libraries(app PRIVATE ${TULA_DEPS})

@param VAR_NAME Variable to append the target name to (usually TULA_DEPS)
@param PACKAGE_NAME Package name (e.g., Eigen3, Yaml)
]=======================================================================]
function(tula_deps_add VAR_NAME PACKAGE_NAME)
    # Check if target already exists (idempotent)
    if(TARGET tula::${PACKAGE_NAME})
        verbose_message("tula::${PACKAGE_NAME} already loaded")
        set(${VAR_NAME} "${${VAR_NAME}};tula::${PACKAGE_NAME}" CACHE INTERNAL "")
        return()
    endif()
    
    # Get mode from variable set by toolchain: TULA_<PACKAGE>_MODE
    string(TOUPPER ${PACKAGE_NAME} _pkg_upper)
    set(_mode_var "TULA_${_pkg_upper}_MODE")
    
    if(NOT DEFINED ${_mode_var})
        message(FATAL_ERROR 
            "Mode not set for ${PACKAGE_NAME}.\n"
            "  Expected variable: ${_mode_var}\n"
            "  Set this variable or run 'conan install' to generate toolchain.")
    endif()
    
    set(_mode "${${_mode_var}}")
    verbose_message("Loading ${PACKAGE_NAME} (mode=${_mode})")
    
    # Dispatch to mode-specific function
    if(_mode STREQUAL "auto")
        _tula_deps_try_auto(${PACKAGE_NAME})
    elseif(_mode STREQUAL "conan")
        _tula_deps_dispatch(${PACKAGE_NAME} conan)
    elseif(_mode STREQUAL "cpm")
        _tula_deps_dispatch(${PACKAGE_NAME} cpm)
    elseif(_mode STREQUAL "system")
        _tula_deps_dispatch(${PACKAGE_NAME} system)
    else()
        message(FATAL_ERROR "Unknown mode '${_mode}' for ${PACKAGE_NAME}")
    endif()
    
    # Verify target was created
    if(NOT TARGET tula::${PACKAGE_NAME})
        if(NOT CMAKE_CXX_COMPILER_LOADED)
            # Toolchain phase: CPM/system packages may require CXX language.
            # Register for deferred post-project() retry regardless of mode.
            list(APPEND TULA_DEFERRED_PKGS "${PACKAGE_NAME}")
            set(TULA_DEFERRED_PKGS "${TULA_DEFERRED_PKGS}" CACHE INTERNAL
                "Packages deferred from toolchain phase for post-project() retry")
            verbose_message("Deferred tula::${PACKAGE_NAME} for post-project() retry")
            return()  # Don't append to TULA_DEPS yet - will be added on successful retry
        endif()
        message(FATAL_ERROR
            "Failed to create tula::${PACKAGE_NAME}.\n"
            "  Mode: ${_mode}\n"
            "  Check tula_${PACKAGE_NAME}_add_${_mode}() function.")
    endif()
    
    # Append to cache variable (works across function scopes)
    set(${VAR_NAME} "${${VAR_NAME}};tula::${PACKAGE_NAME}" CACHE INTERNAL "")
    verbose_message("Added tula::${PACKAGE_NAME} to ${VAR_NAME}")
endfunction()

#[=======================================================================[
@brief Try auto mode: conan -> cpm -> system (internal)

@param PACKAGE_NAME Package name
]=======================================================================]
function(_tula_deps_try_auto PACKAGE_NAME)
    # Try conan first
    if(COMMAND tula_${PACKAGE_NAME}_add_conan)
        verbose_message("AUTO: trying conan for ${PACKAGE_NAME}")
        cmake_language(CALL tula_${PACKAGE_NAME}_add_conan)
        if(TARGET tula::${PACKAGE_NAME})
            verbose_message("AUTO: ${PACKAGE_NAME} loaded via conan")
            return()
        endif()
    endif()
    
    # Try cpm second
    if(COMMAND tula_${PACKAGE_NAME}_add_cpm)
        verbose_message("AUTO: trying cpm for ${PACKAGE_NAME}")
        cmake_language(CALL tula_${PACKAGE_NAME}_add_cpm)
        if(TARGET tula::${PACKAGE_NAME})
            verbose_message("AUTO: ${PACKAGE_NAME} loaded via cpm")
            return()
        endif()
    endif()
    
    # Try system last
    if(COMMAND tula_${PACKAGE_NAME}_add_system)
        verbose_message("AUTO: trying system for ${PACKAGE_NAME}")
        cmake_language(CALL tula_${PACKAGE_NAME}_add_system)
        if(TARGET tula::${PACKAGE_NAME})
            verbose_message("AUTO: ${PACKAGE_NAME} loaded via system")
            return()
        endif()
    endif()
    
    if(NOT CMAKE_CXX_COMPILER_LOADED)
        # Toolchain phase: CPM was skipped, package may succeed on deferred retry
        verbose_message("AUTO: ${PACKAGE_NAME} not loaded in toolchain phase; will retry post-project()")
        return()
    endif()

    message(FATAL_ERROR
        "AUTO mode failed for ${PACKAGE_NAME}.\n"
        "  Tried: conan, cpm, system\n"
        "  None succeeded in creating tula::${PACKAGE_NAME}")
endfunction()

#[=======================================================================[
@brief Dispatch to package-specific add function (internal)

@param PACKAGE_NAME Package name
@param MODE Mode (conan, cpm, system)
]=======================================================================]
function(_tula_deps_dispatch PACKAGE_NAME MODE)
    set(_func "tula_${PACKAGE_NAME}_add_${MODE}")
    
    if(NOT COMMAND ${_func})
        message(FATAL_ERROR 
            "Function ${_func} not found.\n"
            "  Package ${PACKAGE_NAME} may not support '${MODE}' mode.\n"
            "  Check that the package cmake file defines this function.")
    endif()
    
    cmake_language(CALL ${_func})
endfunction()
