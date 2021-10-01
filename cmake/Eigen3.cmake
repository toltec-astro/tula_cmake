include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(Eigen3 "conan")

option(USE_EIGEN3_WITH_MKL "Use intel mkl library if installed" ON)
option(USE_EIGEN3_MULTITHREADING "Enable multithreading inside Eigen3" ON)

# get perf libs

set(eigen3_libs "")
set(eigen3_defs "")

if (USE_EIGEN3_MULTITHREADING OR USE_EIGEN3_WITH_MKL)
    include(perflibs)
    set(eigen3_libs ${eigen3_libs} tula::perflibs)
    if (NOT MKL_FOUND AND USE_EIGEN3_WITH_MKL)
        verbose_message("USE_EIGEN3_WITH_MKL=ON but MKL is not found. Set to OFF. To enable, set USE_INTEL_ONEAPI=ON")
        set_property(CACHE USE_EIGEN3_WITH_MKL PROPERTY VALUE OFF)
    endif()
    if (USE_EIGEN3_WITH_MKL)
        set(eigen3_defs ${eigen3_defs} EIGEN_USE_MKL_ALL)
    endif()
    if (USE_EIGEN3_MULTITHREADING)
        # nothing
    else()
        set(eigen3_defs ${eigen3_defs} EIGEN_DONT_PARALLELIZE)
    endif()
endif()

if (USE_INSTALLED_EIGEN3)
    verbose_message("Use system installed Eigen3.")
    find_package(Eigen3 3.4 REQUIRED CONFIG)
    set(eigen3_libs ${eigen3_libs} Eigen3:Eigen)
else()
    if (CONAN_INSTALL_EIGEN3)
        include(conan_helper)
        ConanHelper(REQUIRES
            eigen/[>=3.4]
            )
        find_package(Eigen3 REQUIRED MODULE)
        verbose_message("Use conan installed Eigen3")
        set(eigen3_libs ${eigen3_libs} Eigen3::Eigen)
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(eigen GIT "https://gitlab.com/libeigen/eigen.git" "3.4"
            ADD_SUBDIR CONFIG_SUBDIR
                EIGEN_TEST_CXX11=OFF
                EIGEN_BUILD_BTL=OFF
                EIGEN_BUILD_DOC=OFF
                BUILD_TESTING=OFF
                EIGEN_LEAVE_TEST_IN_ALL_TARGET=OFF
            # REGISTER_PACKAGE
            #     Eigen3 INCLUDE_CONTENT
            #     "set(EIGEN3_FOUND TRUE)\nset(Eigen3_VERSION \"fch_registered\")\nset(EIGEN3_INCLUDE_DIR \${eigen_SOURCE_DIR})\n"
            )
        verbose_message("Use fetchcontent Eigen3.")
        set(eigen3_libs ${eigen3_libs} Eigen3::Eigen)
    endif()
endif()
# Not sure if this is needed
if (TARGET eigen)
    set_property(
        TARGET eigen
        APPEND PROPERTY
        INTERFACE_COMPILE_DEFINITIONS ${eigen3_defs}
    )
endif()

include(make_tula_target)
make_tula_target(Eigen3 ${eigen3_libs})
target_compile_definitions(tula_Eigen3 INTERFACE ${eigen3_defs})
if (VERBOSE_MESSAGE)
    foreach (def ${eigen3_defs})
        verbose_message("Eigen3 defined: ${def}")
    endforeach()
endif()
