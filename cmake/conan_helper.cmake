include_guard(GLOBAL)
include(verbose_message)

function(_verbose_message msg)
    verbose_message("conan_helper: ${msg}")
endfunction()

set(conan_dir ${CMAKE_BINARY_DIR})
set(conan_cmake_file ${conan_dir}/conan.cmake)
set(CMAKE_MODULE_PATH "${conan_dir}" ${CMAKE_MODULE_PATH})
set(CMAKE_PREFIX_PATH "${conan_dir}" ${CMAKE_PREFIX_PATH})

if(NOT EXISTS "${conan_cmake_file}")
  _verbose_message("Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
  file(DOWNLOAD "https://raw.githubusercontent.com/conan-io/cmake-conan/develop/conan.cmake"
                "${conan_cmake_file}"
                # EXPECTED_HASH SHA256=396e16d0f5eabdc6a14afddbcfff62a54a7ee75c6da23f32f7a31bc85db23484
                # TLS_VERIFY ON
                )
endif()
include(${conan_cmake_file})

function(MakeConanInstallArgs)

    conan_cmake_autodetect(settings BUILD_TYPE "Release")

    # Additional settings has to be provided via env.
    set(env_list
        ENV CC=${CMAKE_C_COMPILER}
        ENV CXX=${CMAKE_CXX_COMPILER}
        )

    set(conan_install_settings ${settings} PARENT_SCOPE)
    set(conan_install_env_list ${env_list} PARENT_SCOPE)

endfunction()

function(ConanHelper)
    set(svargs BUILD)
    set(mvargs REQUIRES OPTIONS)
    cmake_parse_arguments(PARSE_ARGV 0 CNH "" "${svargs}" "${mvargs}")
    if (NOT CNH_BUILD)
        set(CNH_BUILD "outdated")
    endif()
    set(requires "")
    foreach(require ${CNH_REQUIRES})
        set(requires ${requires} ${require})
    endforeach()
    set(config_args "")
    if (CNH_OPTIONS)
        set(options "")
        foreach(option ${CNH_OPTIONS})
            set(options ${options} ${option})
        endforeach()
        set(config_args OPTIONS ${options})
    endif()
    conan_cmake_configure(REQUIRES
        ${requires}
        ${config_args}
        GENERATORS cmake_find_package)
    MakeConanInstallArgs()
    conan_cmake_install(PATH_OR_REFERENCE ${CMAKE_CURRENT_BINARY_DIR}
                BUILD ${CNH_BUILD}
                REMOTE conancenter
                INSTALL_FOLDER ${CMAKE_BINARY_DIR}
                SETTINGS ${conan_install_settings}
                ${conan_install_env_list}
                )
endfunction()
