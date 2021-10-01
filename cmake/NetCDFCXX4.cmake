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
        FetchContentHelper(netcdfcxx4 GIT https://github.com/Unidata/netcdf-cxx4.git "master"
            ADD_SUBDIR CONFIG_SUBDIR
                ENABLE_DOXYGEN=OFF
                BUILD_SHARED_LIBS=OFF
                NCXX_ENABLE_TESTS=OFF
                ENABLE_COVERAGE_TESTS=OFF
                ENABLE_LARGE_FILE_TESTS=OFF
            )
        verbose_message("Use fetchcontent NetCDFCXX4.")
        set(netcdfcxx4_libs ${netcdfcxx4_libs}  netCDF::netcdf-cxx4)
    endif()
endif()

if (VERBOSE_MESSAGE)
    include(print_properties)
    foreach (lib ${netcdfcxx4_libs})
        print_target_properties(${lib})
    endforeach()
endif()

add_library(tula_netcdfcxx4 INTERFACE)
target_link_libraries(tula_netcdfcxx4 INTERFACE ${netcdfcxx4_libs})
if (VERBOSE_MESSAGE)
    include(print_properties)
    print_target_properties(tula_netcdfcxx4)
endif()
add_library(tula::NetCDFCXX4 ALIAS tula_netcdfcxx4)
