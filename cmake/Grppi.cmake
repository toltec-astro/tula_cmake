include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(Grppi "fetch")


set(grppi_libs "")

# make available the perflibs
include(perflibs)
set(grppi_libs ${grppi_libs} tula::perflibs)


if (USE_INSTALLED_GRPPI)
    messsage(FATAL_ERROR "GRPPI does not support use installed.")
else()
    if (CONAN_INSTALL_GRPPI)
        messsage(FATAL_ERROR "GRPPI does not support conan install.")
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(grppi GIT "https://github.com/arcosuc3m/grppi.git" master)
        # the grppi cmake does not do much so we just use our own
        # This is from grppi cmake checking compilers
        # Set specific options depending on compiler
        if (${CMAKE_CXX_COMPILER_ID} STREQUAL "Clang")
          if (NOT (${CMAKE_CXX_COMPILER_VERSION} VERSION_GREATER 3.9.0))
            message(FATAL_ERROR "Clang version " ${CMAKE_CXX_COMPILER_VERSION}
                " not supported. Upgrade to 3.9 or above.")
          endif ()
        elseif (${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
          if (NOT (${CMAKE_CXX_COMPILER_VERSION} VERSION_GREATER 6.0))
            message(FATAL_ERROR "g++ version " ${CMAKE_CXX_COMPILER_VERSION}
                " not supported. Upgrade to 6.0 or above.")
          else ()
            if (${CMAKE_CXX_COMPILER_VERSION} VERSION_GREATER 7.0)
              #g++ 7 warns in non C++17 for over-aligned new otherwise
              add_compile_options(-faligned-new)
            endif ()
          endif ()
        elseif (${CMAKE_CXX_COMPILER_ID} STREQUAL "Intel")
          message(WARNING "Intel compiler is not currently supported")
        endif ()
        add_library(grppi INTERFACE)
        target_include_directories(grppi SYSTEM INTERFACE ${grppi_SOURCE_DIR}/include)
        if (OpenMP_FOUND)
            target_compile_definitions(grppi INTERFACE "-DGRPPI_OMP")
        endif()
        if (NOT Threads_FOUND)
            message(FATAL_ERROR "Grppi requires threads lib.")
        endif()
        target_link_libraries(grppi tula::perflibs)
        add_library(grppi::grppi ALIAS grppi)
        verbose_message("Use fetchcontent Grppi.")
        set(grppi_libs ${grppi_libs} grppi::grppi)
    endif()
endif()

if (VERBOSE_MESSAGE)
    include(print_properties)
    foreach (lib ${grppi_libs})
        print_target_properties(${lib})
    endforeach()
endif()

add_library(tula_grppi INTERFACE)
target_link_libraries(tula_grppi INTERFACE ${grppi_libs})
if (VERBOSE_MESSAGE)
    include(print_properties)
    print_target_properties(tula_grppi)
endif()
add_library(tula::Grppi ALIAS tula_grppi)
