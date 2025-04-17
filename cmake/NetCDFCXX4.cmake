include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(NetCDFCXX4 "fetch")


set(netcdfcxx4_libs "")

# make available eigen
if (NOT TARGET tula::NetCDF)
    include(NetCDF)
endif()

if (USE_INSTALLED_NETCDFCXX4)
    verbose_message("Use system installed NetCDFCXX4.")
    find_package(netCDF-CXX4 REQUIRED CONFIG)
    set(netcdfcxx4_libs ${netcdfcxx4_libs} netCDF::netcdf-cxx4)
else()
    if (CONAN_INSTALL_NETCDFCXX4)
        message(FATAL_ERROR "NetCDFCXX4 does not support conan install")
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(netcdfcxx4 GIT https://github.com/Unidata/netcdf-cxx4.git "main"
            ADD_SUBDIR CONFIG_SUBDIR
                ENABLE_DOXYGEN=OFF
                BUILD_SHARED_LIBS=OFF
                NCXX_ENABLE_TESTS=OFF
                ENABLE_COVERAGE_TESTS=OFF
                ENABLE_LARGE_FILE_TESTS=OFF
            )
        # Turn off some warnings
        set_property(
            TARGET netcdf-cxx4
            APPEND PROPERTY
            COMPILE_OPTIONS
            -Wno-sign-conversion -Wno-shorten-64-to-32
            -Wno-mismatched-new-delete
            -Wno-tautological-overlap-compare
            -Wno-unused-private-field
        )

        verbose_message("Use fetchcontent NetCDFCXX4.")
        set(netcdfcxx4_libs ${netcdfcxx4_libs}  netCDF::netcdf-cxx4)
    endif()
endif()

include(make_tula_target)
make_tula_target(NetCDFCXX4 ${netcdfcxx4_libs})
