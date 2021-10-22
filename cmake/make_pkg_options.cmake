include_guard(GLOBAL)

# A function to create options for specifying how the
# package is to be made available.
function(make_pkg_options name default_option)

    set(use_installed OFF)
    set(conan_install OFF)
    set(fetch OFF)
    if (default_option STREQUAL "installed")
        verbose_message("Default use installed ${name}.")
        set(use_installed ON)
    elseif (default_option STREQUAL "conan")
        verbose_message("Default conan instal ${name}.")
        set(conan_install ON)
    elseif (default_option STREQUAL "fetch")
        verbose_message("Default fetch ${name}.")
        set(fetch ON)
    else()
        message(FATAL_ERROR "Not a valid default option")
    endif()

    string(TOUPPER ${name} name_ac)

    # first set all the three to OFF, then check if they are all off
    # apply the default
    option(USE_INSTALLED_${name_ac} "Use installed ${name}" OFF)
    option(CONAN_INSTALL_${name_ac} "Install ${name} using conan." OFF)
    option(FETCH_${name_ac} "Include ${name} using fetch content." OFF)

    if (NOT USE_INSTALLED_${name_ac} AND NOT CONAN_INSTALL_${name_ac} AND NOT FETCH_${name_ac})
        # apply the defaunt
        set_property(CACHE USE_INSTALLED_${name_ac} PROPERTY VALUE ${use_installed})
        set_property(CACHE CONAN_INSTALL_${name_ac} PROPERTY VALUE ${conan_install})
        set_property(CACHE FETCH_${name_ac} PROPERTY VALUE ${fetch})
    endif()
    verbose_message("User setting for ${name_ac}:")
    verbose_message("  USE_INSTALLED_${name_ac}: ${USE_INSTALLED_${name_ac}}")
    verbose_message("  CONAN_INSTALL_${name_ac}: ${CONAN_INSTALL_${name_ac}}")
    verbose_message("  FETCH_${name_ac}: ${FETCH_${name_ac}}")
    # if (FETCH_${name_ac})
    #     if(CONAN_INSTALL_${name_ac} OR USE_INSTALLED_${name_ac})
    #         verbose_message("FETCH_${name_ac}=ON, ignore installed/conan libs.")
    #         set_property(CACHE USE_INSTALLED_${name_ac} PROPERTY VALUE OFF)
    #         set_property(CACHE CONAN_INSTALL_${name_ac} PROPERTY VALUE OFF)
    #     endif()
    # endif()
endfunction()
