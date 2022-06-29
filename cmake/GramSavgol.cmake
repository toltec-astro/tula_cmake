include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(GramSavgol "fetch")


set(gramsavgol_libs "")

# make available eigen
if (NOT TARGET tula::Eigen3)
    include(Eigen3)
endif()
if (NOT TARGET tula::Boost)
    include(Boost)
endif()

set(gramsavgol_libs ${gramsavgol_libs} tula::Eigen3 tula::Boost)


if (USE_INSTALLED_GRAMSAVGOL)
    messsage(FATAL_ERROR "GRAMSAVGOL does not support use installed.")
else()
    if (CONAN_INSTALL_GRAMSAVGOL)
        messsage(FATAL_ERROR "GRAMSAVGOL does not support conan install.")
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(gramsavgol GIT "https://github.com/arntanguy/gram_savitzky_golay.git"  master)
        add_library(
            gramsavgol STATIC
            ${gramsavgol_SOURCE_DIR}/src/gram_savitzky_golay.cpp
            ${gramsavgol_SOURCE_DIR}/src/spatial_filters.cpp
            )
        target_include_directories(gramsavgol SYSTEM PUBLIC ${gramsavgol_SOURCE_DIR}/include)
        target_link_libraries(gramsavgol PUBLIC
            tula::Eigen3
            tula::Boost
            )
        add_library(gramsavgol::gramsavgol ALIAS gramsavgol)
        verbose_message("Use fetchcontent Gramgramsavgol.")
        set(gramsavgol_libs ${gramsavgol_libs} gramsavgol::gramsavgol)
    endif()
endif()

include(make_tula_target)
make_tula_target(GramSavgol ${gramsavgol_libs})
