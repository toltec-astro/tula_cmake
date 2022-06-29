include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(Savgol "fetch")


set(savgol_libs "")

# make available eigen
if (NOT TARGET tula::Eigen3)
    include(Eigen3)
endif()
set(savgol_libs ${savgol_libs} tula::Eigen3)


if (USE_INSTALLED_SAVGOL)
    messsage(FATAL_ERROR "SAVGOL does not support use installed.")
else()
    if (CONAN_INSTALL_SAVGOL)
        messsage(FATAL_ERROR "SAVGOL does not support conan install.")
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(savgol GIT "https://github.com/robotsorcerer/Savitzky-Golay.git"  master)
        add_library(
            savgol STATIC
            ${savgol_SOURCE_DIR}/savgol.cpp
            )
        target_include_directories(savgol SYSTEM PUBLIC ${savgol_SOURCE_DIR}/include)
        target_link_libraries(savgol PUBLIC
            tula::Eigen3
            )
        add_library(savgol::savgol ALIAS savgol)
        verbose_message("Use fetchcontent Savgol.")
        set(savgol_libs ${savgol_libs} savgol::savgol)
    endif()
endif()

include(make_tula_target)
make_tula_target(Savgol ${savgol_libs})
