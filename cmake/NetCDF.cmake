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
        ConanHelper(REQUIRES
            netcdf/[>=4.7.4]
            )
        find_package(netCDF REQUIRED MODULE)
        verbose_message("Use conan installed NetCDF")
        set(netcdf_libs ${netcdf_libs} netCDF::netcdf)
    else()
        # fetch content
        message(FATAL_ERROR "NetCDF does not support fetch content.")
    endif()
endif()

include(make_tula_target)
make_tula_target(NetCDF ${netcdf_libs})
