set shell := ["bash", "-euo", "pipefail", "-c"]

root := justfile_directory()
build_root := root / "build"
spack_root := root / "examples/spack"

default:
    @just --list

# Configure, build, and test the installed TulaCMake consumer fixture.
unit:
    cmake -S "{{ root }}" -B "{{ build_root }}/unit" -G Ninja \
        -DCMAKE_BUILD_TYPE=Debug
    cmake --build "{{ build_root }}/unit" --parallel
    ctest --test-dir "{{ build_root }}/unit" --output-on-failure

# Concretize, test, install, and run both GCC 13 vertical-slice environments.
spack-matrix spack="spack":
    #!/usr/bin/env bash
    set -euo pipefail
    spack_cmd="{{ spack }}"
    common=(-C "{{ spack_root }}/config" -C "{{ spack_root }}/config/devcontainer")

    run_environment() {
        local name="$1"
        local expected="$2"
        local environment="{{ spack_root }}/environments/$name"

        "$spack_cmd" "${common[@]}" -e "$environment" concretize --force
        # Develop specs keep a stable DAG hash while their source changes.
        # Overwrite ensures this acceptance test exercises the current checkout.
        "$spack_cmd" "${common[@]}" -e "$environment" install \
            --yes-to-all \
            --test=all \
            --overwrite \
            --show-log-on-error
        "$spack_cmd" "${common[@]}" -e "$environment" find -clv

        local output
        output="$("$environment/.spack-view/bin/tula_downstream" 2>&1)"
        printf '%s\n' "$output"
        grep -F "$expected" <<<"$output"
    }

    run_environment \
        default \
        "libA=vanilla perflibs.openmp=enabled libB=fast"
    run_environment \
        alternate \
        "libA=chocolate perflibs.openmp=disabled libB=safe"

# Run the complete CMake and Spack acceptance surface.
check spack="spack": unit
    just spack-matrix "{{ spack }}"
