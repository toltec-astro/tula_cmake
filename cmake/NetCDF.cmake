include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(NetCDF "conan")


set(netcdf_libs "")

if (USE_INSTALLED_NETCDF)
    verbose_message("Use system installed NetCDF.")
    find_package(NetCDF REQUIRED CONFIG)
    set(netcdf_libs ${netcdf_libs} netCDF::netcdf)
else()
    if (CONAN_INSTALL_NETCDF)
        include(conan_helper)
        conan_cmake_configure(REQUIRES
            netcdf/[>=4.7.4]
            GENERATORS cmake_find_package)
        conan_cmake_install(PATH_OR_REFERENCE .
                    BUILD outdated
                    REMOTE conancenter
                    SETTINGS ${conan_install_settings}
                    ${conan_install_env_list}
                    )
        find_package(netCDF REQUIRED MODULE)
        verbose_message("Use conan installed NetCDF")
        set(netcdf_libs ${netcdf_libs} netCDF::netcdf)
    else()
        # fetch content
        message(FATAL_ERROR "NetCDF does not support fetch content.")
    endif()
endif()

if (VERBOSE_MESSAGE)
    include(print_properties)
    foreach (lib ${netcdf_libs})
        print_target_properties(${lib})
    endforeach()
endif()

add_library(tula_netcdf INTERFACE)
target_link_libraries(tula_netcdf INTERFACE ${netcdf_libs})
if (VERBOSE_MESSAGE)
    include(print_properties)
    print_target_properties(tula_netcdf)
endif()
add_library(tula::NetCDF ALIAS tula_netcdf)
