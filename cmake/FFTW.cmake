include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(FFTW "conan")

set(fftw_libs "")

if (USE_INSTALLED_FFTW)
    find_library(
        FFTW_DOUBLE_LIB
        NAMES "fftw3"
        PATHS ${PKG_FFTW_LIBRARY_DIRS} ${LIB_INSTALL_DIR}
        )

    find_library(
        FFTW_DOUBLE_THREADS_LIB
        NAMES "fftw3_threads"
        PATHS ${PKG_FFTW_LIBRARY_DIRS} ${LIB_INSTALL_DIR}
        )

    find_library(
        FFTW_DOUBLE_OPENMP_LIB
        NAMES "fftw3_omp"
        PATHS ${PKG_FFTW_LIBRARY_DIRS} ${LIB_INSTALL_DIR}
        )

    find_library(
        FFTW_DOUBLE_MPI_LIB
        NAMES "fftw3_mpi"
        PATHS ${PKG_FFTW_LIBRARY_DIRS} ${LIB_INSTALL_DIR}
        )

    find_library(
        FFTW_FLOAT_LIB
        NAMES "fftw3f"
        PATHS ${PKG_FFTW_LIBRARY_DIRS} ${LIB_INSTALL_DIR}
        )

    find_library(
        FFTW_FLOAT_THREADS_LIB
        NAMES "fftw3f_threads"
        PATHS ${PKG_FFTW_LIBRARY_DIRS} ${LIB_INSTALL_DIR}
        )

    find_library(
        FFTW_FLOAT_OPENMP_LIB
        NAMES "fftw3f_omp"
        PATHS ${PKG_FFTW_LIBRARY_DIRS} ${LIB_INSTALL_DIR}
        )

    find_library(
        FFTW_FLOAT_MPI_LIB
        NAMES "fftw3f_mpi"
        PATHS ${PKG_FFTW_LIBRARY_DIRS} ${LIB_INSTALL_DIR}
        )

    find_library(
        FFTW_LONGDOUBLE_LIB
        NAMES "fftw3l"
        PATHS ${PKG_FFTW_LIBRARY_DIRS} ${LIB_INSTALL_DIR}
        )

    find_library(
        FFTW_LONGDOUBLE_THREADS_LIB
        NAMES "fftw3l_threads"
        PATHS ${PKG_FFTW_LIBRARY_DIRS} ${LIB_INSTALL_DIR}
        )

    find_library(FFTW_LONGDOUBLE_OPENMP_LIB
        NAMES "fftw3l_omp"
        PATHS ${PKG_FFTW_LIBRARY_DIRS} ${LIB_INSTALL_DIR}
        )

    find_library(FFTW_LONGDOUBLE_MPI_LIB
        NAMES "fftw3l_mpi"
        PATHS ${PKG_FFTW_LIBRARY_DIRS} ${LIB_INSTALL_DIR}
        )

    find_path(FFTW_INCLUDE_DIRS
        NAMES "fftw3.h"
        PATHS ${PKG_FFTW_INCLUDE_DIRS} ${INCLUDE_INSTALL_DIR}
        )

    #--------------------------------------- components

    if (FFTW_DOUBLE_LIB)
        set(FFTW_DOUBLE_LIB_FOUND TRUE)
    else()
        set(FFTW_DOUBLE_LIB_FOUND FALSE)
    endif()

    if (FFTW_FLOAT_LIB)
        set(FFTW_FLOAT_LIB_FOUND TRUE)
    else()
        set(FFTW_FLOAT_LIB_FOUND FALSE)
    endif()

    if (FFTW_LONGDOUBLE_LIB)
        set(FFTW_LONGDOUBLE_LIB_FOUND TRUE)
    else()
        set(FFTW_LONGDOUBLE_LIB_FOUND FALSE)
    endif()

    if (FFTW_DOUBLE_THREADS_LIB)
        set(FFTW_DOUBLE_THREADS_LIB_FOUND TRUE)
    else()
        set(FFTW_DOUBLE_THREADS_LIB_FOUND FALSE)
    endif()

    if (FFTW_FLOAT_THREADS_LIB)
        set(FFTW_FLOAT_THREADS_LIB_FOUND TRUE)
    else()
        set(FFTW_FLOAT_THREADS_LIB_FOUND FALSE)
    endif()

    if (FFTW_LONGDOUBLE_THREADS_LIB)
        set(FFTW_LONGDOUBLE_THREADS_LIB_FOUND TRUE)
    else()
        set(FFTW_LONGDOUBLE_THREADS_LIB_FOUND FALSE)
    endif()

    if (FFTW_DOUBLE_OPENMP_LIB)
        set(FFTW_DOUBLE_OPENMP_LIB_FOUND TRUE)
    else()
        set(FFTW_DOUBLE_OPENMP_LIB_FOUND FALSE)
    endif()

    if (FFTW_FLOAT_OPENMP_LIB)
        set(FFTW_FLOAT_OPENMP_LIB_FOUND TRUE)
    else()
        set(FFTW_FLOAT_OPENMP_LIB_FOUND FALSE)
    endif()

    if (FFTW_LONGDOUBLE_OPENMP_LIB)
        set(FFTW_LONGDOUBLE_OPENMP_LIB_FOUND TRUE)
    else()
        set(FFTW_LONGDOUBLE_OPENMP_LIB_FOUND FALSE)
    endif()

    if (FFTW_DOUBLE_MPI_LIB)
        set(FFTW_DOUBLE_MPI_LIB_FOUND TRUE)
    else()
        set(FFTW_DOUBLE_MPI_LIB_FOUND FALSE)
    endif()

    if (FFTW_FLOAT_MPI_LIB)
        set(FFTW_FLOAT_MPI_LIB_FOUND TRUE)
    else()
        set(FFTW_FLOAT_MPI_LIB_FOUND FALSE)
    endif()

    if (FFTW_LONGDOUBLE_MPI_LIB)
        set(FFTW_LONGDOUBLE_MPI_LIB_FOUND TRUE)
    else()
        set(FFTW_LONGDOUBLE_MPI_LIB_FOUND FALSE)
    endif()


    add_library(fftw INTERFACE)
    target_include_directories(fftw INTERFACE ${FFTW_INCLUDE_DIRS})
    target_link_libraries(fftw INTERFACE 
                            ${FFTW_DOUBLE_LIB}
                            ${FFTW_FLOAT_LIB}
                            ${FFTW_LONGDOUBLE_LIB}
                            ${FFTW_DOUBLE_THREADS_LIB}
                            ${FFTW_FLOAT_THREADS_LIB}
                            ${FFTW_LONGDOUBLE_THREADS_LIB}
                            ${FFTW_DOUBLE_OPENMP_LIB}
                            ${FFTW_FLOAT_OPENMP_LIB}
                            ${FFTW_LONGDOUBLE_OPENMP_LIB}
                            ${FFTW_DOUBLE_MPI_LIB}
                            ${FFTW_FLOAT_MPI_LIB} 
                            ${FFTW_LONGDOUBLE_MPI_LIB} z)
    
    add_library(FFTW::FFTW ALIAS fftw)
    set(fftw_libs ${fftw_libs} FFTW::FFTW)

else()
    if (CONAN_INSTALL_FFTW)
        include(conan_helper)
        ConanHelper(REQUIRES
            fftw/[>=3.3.9]
            )
        find_package(fftw REQUIRED MODULE)
        verbose_message("Use conan installed FFTW")
        set(fftw_libs ${eigen3_libs} fftw::fftw)
    endif()
endif()

include(make_tula_target)
make_tula_target(FFTW ${fftw_libs})