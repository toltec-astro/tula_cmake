include_guard(GLOBAL)

include(verbose_message)

## CMake version check
set(COMMON_SETTINGS_MINIMUM_VERSION "3.20")
if(${CMAKE_VERSION} VERSION_LESS ${COMMON_SETTINGS_MINIMUM_VERSION})
    message(FATAL_ERROR "CommonSettings.cmake require minimum cmake version ${COMMON_SETTINGS_MINIMUM_VERSION}")
endif()

## No build-in-src guard
file(TO_CMAKE_PATH "${PROJECT_BINARY_DIR}/CMakeLists.txt" LOC_PATH)
if(EXISTS "${LOC_PATH}")
    message(FATAL_ERROR "You cannot build in a source directory (or any directory with a CMakeLists.txt file). Please make a build subdirectory. Feel free to remove CMakeCache.txt and CMakeFiles.")
endif()

## Detect build type if not specified
include(build_type)

## Some sensible settings
set_property(GLOBAL PROPERTY ALLOW_DUPLICATE_CUSTOM_TARGETS TRUE)

## Paths and directories
SET(CMAKE_SKIP_BUILD_RPATH  FALSE)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
include(GNUInstallDirs)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
# add this folder for include
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}" ${CMAKE_MODULE_PATH})

## Language settings
enable_language(CXX)
enable_language(C)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

## Platform specifics

if (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    # For brew installed LLVM
    if (CMAKE_CXX_COMPILER_ID STREQUAL Clang)
        get_filename_component(compiler_bindir ${CMAKE_CXX_COMPILER} DIRECTORY)
        get_filename_component(compiler_libdir ${compiler_bindir}/../lib ABSOLUTE)
        verbose_message("Link CXX libs from ${compiler_libdir}")
        set(CMAKE_EXE_LINKER_FLAGS "-L${compiler_libdir} -Wl,-rpath,${compiler_libdir}")
    endif()
else()
    # Non standard GCC path
    if (CMAKE_CXX_COMPILER_ID STREQUAL GNU)
        add_definitions(-Wno-deprecated-declarations)
        # custom gcc paths
        get_filename_component(compiler_bindir ${CMAKE_CXX_COMPILER} DIRECTORY)
        get_filename_component(compiler_libdir ${compiler_bindir}/../lib ABSOLUTE)
        get_filename_component(compiler_lib64dir ${compiler_bindir}/../lib64 ABSOLUTE)
        verbose_message("Link CXX libs from ${compiler_libdir} ${compiler_lib64dir}")
        set(CMAKE_EXE_LINKER_FLAGS "-L${compiler_libdir} -Wl,-rpath,${compiler_libdir} -Wl,-rpath,${compiler_lib64dir}")
    endif()
endif()

if (APPLE)
    set(CMAKE_MACOSX_RPATH TRUE)
    # https://stackoverflow.com/a/33067191/1824372
    SET(CMAKE_C_ARCHIVE_CREATE   "<CMAKE_AR> Scr <TARGET> <LINK_FLAGS> <OBJECTS>")
    SET(CMAKE_CXX_ARCHIVE_CREATE "<CMAKE_AR> Scr <TARGET> <LINK_FLAGS> <OBJECTS>")
    # SET(CMAKE_C_ARCHIVE_FINISH   "<CMAKE_RANLIB> -no_warning_for_no_symbols -c <TARGET>")
    # SET(CMAKE_CXX_ARCHIVE_FINISH "<CMAKE_RANLIB> -no_warning_for_no_symbols -c <TARGET>")
else()
    set(CMAKE_LINK_WHAT_YOU_USE TRUE)
endif()

# copy a dummy clang-tidy file to suppress warning from deps
# configure_file("${CMAKE_CURRENT_LIST_DIR}/src/disable.ctd" "${CMAKE_BINARY_DIR}/.clang-tidy" COPYONLY)
