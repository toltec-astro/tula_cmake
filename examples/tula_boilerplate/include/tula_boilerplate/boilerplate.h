#pragma once

#include <tula_boilerplate/config.h>
#include <tula_boilerplate/version.h>

#include <fmt/format.h>
#include <spdlog/spdlog.h>
#include <string_view>

#include <tula_lib_a/config.h>
#include <tula_perflibs/config.h>

namespace tula_boilerplate {

inline std::string summary()
{
    constexpr std::string_view openmp =
        TULA_PERFLIBS_HAS_OPENMP ? "enabled" : "disabled";
    return fmt::format(
        "libA={} perflibs.openmp={}",
        tula_lib_a::flavor,
        openmp
    );
}

inline void log_summary()
{
    spdlog::info("{}", summary());
}

}  // namespace tula_boilerplate
