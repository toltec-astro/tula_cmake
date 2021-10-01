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

    option(USE_INSTALLED_${name_ac} "Use installed ${name}" ${use_installed})
    option(CONAN_INSTALL_${name_ac} "Install ${name} using conan." ${conan_install})
    option(FETCH_${name_ac} "Include ${name} using fetch content." ${fetch})

    if (FETCH_${name_ac})
        if(CONAN_INSTALL_${name_ac} OR USE_INSTALLED_${name_ac})
            verbose_message("FETCH_${name_ac}=ON, ignore installed/conan libs.")
            set_property(CACHE USE_INSTALLED_${name_ac} PROPERTY VALUE OFF)
            set_property(CACHE CONAN_INSTALL_${name_ac} PROPERTY VALUE OFF)
        endif()
    endif()
endfunction()
