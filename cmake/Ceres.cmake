include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(Ceres "conan")

option(USE_CERES_MULTITHREADING "Enable multithreading inside Ceres" ON)

set(ceres_libs "")

if (USE_CERES_MULTITHREADING)
    include(perflibs)
    set(ceres_libs ${ceres_libs} tula::perflibs)
endif()

# make available eigen
if (NOT TARGET tula::Eigen3)
    # Fetch eigen if requested fetch ceres
    if (FETCH_CERES)
        verbose_message("FETCH_CERES=ON, set FETCH_EIGEN3=ON")
        set(FETCH_EIGEN3 ON)
    endif()
    include(Eigen3)
endif()

if (USE_INSTALLED_CERES)
    verbose_message("Use system installed Ceres.")
    find_package(Ceres REQUIRED CONFIG)
    set(ceres_libs ${ceres_libs} Ceres::ceres)
else()
    if (CONAN_INSTALL_CERES)
        include(conan_helper)
        ConanHelper(REQUIRES
                eigen/[>=3.4]  # override the dependency
                ceres-solver/[~2.1]
            OPTIONS
                ceres-solver:use_glog=True
                ceres-solver:use_gflags=True
                )
        # set(ceres_config "")
        # if (USE_CERES_MULTITHREADING)
        #     set(ceres_config ${ceres_config} "ceres-solver:use_CXX11_threads=True")
        # else()
        #     set(ceres_config ${ceres_config} "ceres-solver:use_CXX11_threads=False")
        # endif()
        find_package(Ceres REQUIRED MODULE)
        verbose_message("Use conan installed Ceres")
        set(ceres_libs ${ceres_libs} Ceres::ceres)
    else()
        # fetch content
        # include(fetchcontent_helper)
        # # gflag
        # set(gflag_config "")
        # if (USE_CERES_MULTITHREADING)
        #     set(gflag_config ${gflag_config} "BUILD_gflags_LIB=ON")
        #     set(gflag_config ${gflag_config} "BUILD_gflags_nothreads_LIB=OFF")
        # else()
        #     set(gflag_config ${gflag_config} "BUILD_gflags_LIB=OFF")
        #     set(gflag_config ${gflag_config} "BUILD_gflags_nothreads_LIB=ON")
        # endif()
        # FetchContentHelper(gflags GIT "https://github.com/gflags/gflags.git" "v2.2.2"
        #     ADD_SUBDIR CONFIG_SUBDIR
        #         BUILD_SHARED_LIBS=OFF
        #         BUILD_STATIC_LIBS=ON
        #         INSTALL_HEADERS=ON
        #         ${gflag_config}
        #     REGISTER_PACKAGE
        #         gflags INCLUDE_CONTENT
        #         "set(gflags_FOUND TRUE)\nset(gflags_VERSION \"fch_registered\")\nmessage(STATUS \"Use fch gflags\")\n"
        #     )
        # if (VERBOSE_MESSAGE)
        #     include(print_properties)
        #     print_target_properties(gflags)
        # endif()
        # glog
        set(glog_config "")
        if (USE_CERES_MULTITHREADING)
            set(glog_config ${glog_config} "WITH_THREADS=ON")
            set(glog_config ${glog_config} "WITH_TLS=ON")
        else()
            set(glog_config ${glog_config} "WITH_THREADS=OFF")
        endif()
        FetchContentHelper(glog GIT "https://github.com/google/glog.git" "v0.5.0"
            ADD_SUBDIR CONFIG_SUBDIR
                BUILD_SHARED_LIBS=OFF
                WITH_GFLAGS=OFF
                WITH_GTEST=OFF
                WITH_PKGCONFIG=OFF
                WITH_SYMBOLIZE=OFF
                WITH_UNWIND=OFF
                BUILD_TESTING=OFF
                ${glog_config}
            # PATCH_SUBDIR
            #     ${FCH_PATCH_DIR}/patch.sh "glog_*.patch"
            REGISTER_PACKAGE
                Glog INCLUDE_CONTENT
                "set(GLOG_FOUND TRUE)\nset(Glog_VERSION \"fch_registered\")\nmessage(STATUS \"Use fch glog\")\n"
            )
        if (VERBOSE_MESSAGE)
            include(print_properties)
            print_target_properties(glog::glog)
        endif()

        # ceres
        set(ceres_config "")
        if (USE_CERES_MULTITHREADING)
            # the ceres cmake checks openmp which may conflict with
            # intel openmp. We'll just use cxx threading
            set(ceres_config ${ceres_config} "CERES_THREADING_MODEL=CXX_THREADS")
        else()
            set(ceres_config ${ceres_config} "CERES_THREADING_MODEL=NO_THREADS")
        endif()
        set(Eigen3_DIR ${eigen_BINARY_DIR})
        # set(Glog_DIR ${glog_BINARY_DIR})
        FetchContentHelper(ceres GIT "https://github.com/ceres-solver/ceres-solver.git" "2.0.0"
            ADD_SUBDIR CONFIG_SUBDIR
                GLOG_PREFER_EXPORTED_GLOG_CMAKE_CONFIGURATION=ON
                MINIGLOG=OFF
                GFLAGS=OFF
                EIGENSPARSE=ON
                SUITESPARSE=OFF
                CXSPARSE=OFF
                ACCELERATESPARSE=OFF
                SCHUR_SPECIALIZATIONS=ON
                BUILD_DOCUMENTATION=OFF
                BUILD_TESTING=OFF
                BUILD_EXAMPLES=OFF
                BUILD_BENCHMARKS=OFF
                BUILD_SHARED_LIBS=OFF
                ${ceres_config}
            PATCH_SUBDIR
                ${FCH_PATCH_DIR}/patch.sh "ceres_*.patch"
            )
        verbose_message("Use fetchcontent Ceres.")
        set(ceres_libs ${ceres_libs} Ceres::ceres)
        # add glog to the link libraries
        set_property(
            TARGET ceres
            APPEND PROPERTY
            INTERFACE_LINK_LIBRARIES glog::glog
            )
        set_property(
            TARGET ceres
            APPEND PROPERTY
            LINK_LIBRARIES glog::glog
            )
    endif()
endif()

include(make_tula_target)
make_tula_target(Ceres ${ceres_libs})
