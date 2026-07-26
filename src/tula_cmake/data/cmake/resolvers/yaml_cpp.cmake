include_guard(GLOBAL)

include(TulaCPM)

function(_tula_yaml_cpp_cpm)
    tula_load_cpm()
    CPMAddPackage(
        NAME yaml_cpp
        URL "${TULA_FEATURE_yaml_cpp_URL}"
        URL_HASH "SHA256=${TULA_FEATURE_yaml_cpp_SHA256}"
        OPTIONS
            "YAML_CPP_BUILD_CONTRIB OFF"
            "YAML_CPP_BUILD_TESTS OFF"
            "YAML_CPP_BUILD_TOOLS OFF"
            "YAML_CPP_INSTALL OFF"
            "YAML_BUILD_SHARED_LIBS OFF"
    )
endfunction()

function(_tula_yaml_cpp_installed)
    find_package(yaml-cpp CONFIG REQUIRED)
endfunction()

function(_tula_yaml_cpp_finalize)
    if(TARGET tula::yaml_cpp)
        return()
    endif()

    if(TARGET yaml-cpp::yaml-cpp)
        set(_yaml_cpp_target yaml-cpp::yaml-cpp)
    elseif(TARGET yaml-cpp)
        set(_yaml_cpp_target yaml-cpp)
    else()
        message(FATAL_ERROR "yaml_cpp: yaml-cpp provider target is unavailable")
    endif()

    add_library(tula_yaml_cpp INTERFACE)
    target_link_libraries(tula_yaml_cpp INTERFACE "${_yaml_cpp_target}")
    add_library(tula::yaml_cpp ALIAS tula_yaml_cpp)
endfunction()

function(tula_resolve_yaml_cpp_conan)
    _tula_yaml_cpp_installed()
    _tula_yaml_cpp_finalize()
endfunction()

function(tula_resolve_yaml_cpp_cpm)
    _tula_yaml_cpp_cpm()
    _tula_yaml_cpp_finalize()
endfunction()

function(tula_resolve_yaml_cpp_system)
    _tula_yaml_cpp_installed()
    _tula_yaml_cpp_finalize()
endfunction()
