#pragma once

#include <fmt/format.h>
#include <spdlog/spdlog.h>

#include <string>
#include <string_view>

#include <tula_lib_a/config.h>

namespace tula_boilerplate {

inline std::string summary()
{
#if TULA_PERFLIBS_HAS_OPENMP
    constexpr std::string_view openmp = "enabled";
#else
    constexpr std::string_view openmp = "disabled";
#endif
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

