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

# Concretize, test, install, and run both GCC 14 vertical-slice environments.
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

# Build the minimal Tula ECSV + CSV-parser closure under both compilers.
tula-component-matrix spack="spack":
    #!/usr/bin/env bash
    set -euo pipefail
    spack_cmd="{{ spack }}"
    environments="{{ root }}/environments/integration/tula_ecsv"

    for compiler in gcc14 llvm20; do
        environment="${environments}/${compiler}"
        "$spack_cmd" -e "$environment" concretize --force

        concrete="$("$spack_cmd" -e "$environment" find -c \
            --format '{name}{@version}{variants}' tula)"
        printf '%s\n' "$concrete"
        for enabled in logging yaml ecsv eigen; do
            grep -F "+${enabled}" <<<"$concrete"
        done
        for disabled in netcdf enum cli perflibs openmp grppi fitting; do
            grep -F "~${disabled}" <<<"$concrete"
        done
        dag="$("$spack_cmd" -e "$environment" find -cd)"
        for adapter in \
            tula-logging \
            tula-yaml-cpp \
            tula-csv-parser \
            tula-eigen3; do
            grep -F "$adapter" <<<"$dag"
        done
        if grep -F "ceres-solver" <<<"$dag"; then
            echo "Minimal ECSV graph unexpectedly contains Ceres" >&2
            exit 1
        fi

        "$spack_cmd" -e "$environment" install \
            --yes-to-all \
            --test=all \
            --overwrite \
            --show-log-on-error

        prefix="$("$spack_cmd" -e "$environment" location -i tula)"
        deps_build="{{ build_root }}/deps-consumer/${compiler}"
        "$spack_cmd" -e "$environment" build-env tula -- \
            cmake --fresh \
                -S "{{ root }}/tests/deps_consumer" \
                -B "$deps_build" \
                -G Ninja \
                -DCMAKE_BUILD_TYPE=Release
        "$spack_cmd" -e "$environment" build-env tula -- \
            cmake --build "$deps_build" --parallel
        "$deps_build/tula_deps_consumer"

        example_build="{{ build_root }}/ecsv-reader/${compiler}"
        "$spack_cmd" -e "$environment" build-env tula -- \
            cmake --fresh \
                -S "{{ root }}/../tula/examples/ecsv_reader" \
                -B "$example_build" \
                -G Ninja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_PREFIX_PATH="$prefix"
        "$spack_cmd" -e "$environment" build-env tula -- \
            cmake --build "$example_build" --parallel

        missing_build="{{ build_root }}/missing-component/${compiler}"
        if "$spack_cmd" -e "$environment" build-env tula -- \
            cmake --fresh \
                -S "{{ root }}/../tula/tests/missing_component" \
                -B "$missing_build" \
                -G Ninja \
                -DCMAKE_PREFIX_PATH="$prefix"; then
            echo "Tula unexpectedly accepted a missing required component" >&2
            exit 1
        fi
    done

# Verify the Tula perflibs component with OpenMP enabled and disabled.
tula-perflibs-matrix spack="spack":
    #!/usr/bin/env bash
    set -euo pipefail
    spack_cmd="{{ spack }}"
    environments="{{ root }}/environments/integration/tula_perflibs"

    for case_spec in \
        gcc14_openmp:1 \
        gcc14_no_openmp:0 \
        llvm20_openmp:1 \
        llvm20_no_openmp:0; do
        environment_name="${case_spec%%:*}"
        expected_openmp="${case_spec##*:}"
        environment="${environments}/${environment_name}"

        "$spack_cmd" -e "$environment" concretize --force
        concrete="$("$spack_cmd" -e "$environment" find -c \
            --format '{name}{@version}{variants}' tula)"
        printf '%s\n' "$concrete"
        grep -F "+perflibs" <<<"$concrete"
        if [[ "$expected_openmp" == 1 ]]; then
            grep -F "+openmp" <<<"$concrete"
        else
            grep -F "~openmp" <<<"$concrete"
        fi
        for disabled in logging yaml ecsv eigen netcdf enum cli grppi fitting; do
            grep -F "~${disabled}" <<<"$concrete"
        done

        dag="$("$spack_cmd" -e "$environment" find -cd)"
        grep -F "tula-perflibs" <<<"$dag"
        for excluded in \
            tula-logging \
            tula-yaml-cpp \
            tula-csv-parser \
            tula-eigen3 \
            ceres-solver \
            netcdf-cxx4; do
            if grep -F "$excluded" <<<"$dag"; then
                echo "Perflibs graph unexpectedly contains ${excluded}" >&2
                exit 1
            fi
        done

        "$spack_cmd" -e "$environment" install \
            --yes-to-all \
            --test=all \
            --overwrite \
            --show-log-on-error

        prefix="$("$spack_cmd" -e "$environment" location -i tula)"
        consumer_build="{{ build_root }}/perflibs-consumer/${environment_name}"
        "$spack_cmd" -e "$environment" build-env tula -- \
            cmake --fresh \
                -S "{{ root }}/../tula/tests/perflibs_consumer" \
                -B "$consumer_build" \
                -G Ninja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_PREFIX_PATH="$prefix" \
                -DEXPECT_OPENMP="$expected_openmp"
        "$spack_cmd" -e "$environment" build-env tula -- \
            cmake --build "$consumer_build" --parallel
        "$spack_cmd" -e "$environment" build-env tula -- \
            ctest --test-dir "$consumer_build" --output-on-failure
    done

# Verify the enum and CLI component closures independently.
tula-enum-cli-matrix spack="spack":
    #!/usr/bin/env bash
    set -euo pipefail
    spack_cmd="{{ spack }}"
    environments="{{ root }}/environments/integration/tula_enum_cli"

    for case_spec in \
        gcc14_enum:enum \
        llvm20_enum:enum \
        gcc14_cli:cli \
        llvm20_cli:cli; do
        environment_name="${case_spec%%:*}"
        component="${case_spec##*:}"
        environment="${environments}/${environment_name}"

        "$spack_cmd" -e "$environment" concretize --force
        concrete="$("$spack_cmd" -e "$environment" find -c \
            --format '{name}{@version}{variants}' tula)"
        printf '%s\n' "$concrete"
        grep -F "+logging" <<<"$concrete"
        grep -F "+enum" <<<"$concrete"
        if [[ "$component" == cli ]]; then
            grep -F "+cli" <<<"$concrete"
        else
            grep -F "~cli" <<<"$concrete"
        fi
        for disabled in yaml ecsv eigen netcdf perflibs openmp grppi fitting; do
            grep -F "~${disabled}" <<<"$concrete"
        done

        dag="$("$spack_cmd" -e "$environment" find -cd)"
        for required in tula-logging tula-bitmask tula-meta-enum; do
            grep -F "$required" <<<"$dag"
        done
        if [[ "$component" == cli ]]; then
            grep -F "tula-clipp" <<<"$dag"
        elif grep -F "tula-clipp" <<<"$dag"; then
            echo "Enum-only graph unexpectedly contains Clipp" >&2
            exit 1
        fi
        for excluded in \
            tula-yaml-cpp \
            tula-csv-parser \
            tula-eigen3 \
            tula-perflibs \
            tula-grppi \
            ceres-solver \
            netcdf-cxx4; do
            if grep -F "$excluded" <<<"$dag"; then
                echo "${component} graph unexpectedly contains ${excluded}" >&2
                exit 1
            fi
        done

        "$spack_cmd" -e "$environment" install \
            --yes-to-all \
            --test=all \
            --overwrite \
            --show-log-on-error

        prefix="$("$spack_cmd" -e "$environment" location -i tula)"
        consumer_build="{{ build_root }}/${component}-consumer/${environment_name}"
        "$spack_cmd" -e "$environment" build-env tula -- \
            cmake --fresh \
                -S "{{ root }}/../tula/tests/${component}_consumer" \
                -B "$consumer_build" \
                -G Ninja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_PREFIX_PATH="$prefix"
        "$spack_cmd" -e "$environment" build-env tula -- \
            cmake --build "$consumer_build" --parallel
        "$spack_cmd" -e "$environment" build-env tula -- \
            ctest --test-dir "$consumer_build" --output-on-failure
    done

# Verify the NetCDF C++ adapter and Tula component in both compiler lanes.
tula-netcdf-matrix spack="spack":
    #!/usr/bin/env bash
    set -euo pipefail
    spack_cmd="{{ spack }}"
    environments="{{ root }}/environments/integration/tula_netcdf"

    for compiler in gcc14 llvm20; do
        environment="${environments}/${compiler}"
        "$spack_cmd" -e "$environment" concretize --force

        concrete="$("$spack_cmd" -e "$environment" find -c \
            --format '{name}{@version}{variants}' tula)"
        printf '%s\n' "$concrete"
        for enabled in logging eigen netcdf; do
            grep -F "+${enabled}" <<<"$concrete"
        done
        for disabled in yaml ecsv enum cli perflibs openmp grppi fitting; do
            grep -F "~${disabled}" <<<"$concrete"
        done

        dag="$("$spack_cmd" -e "$environment" find -cd)"
        for required in \
            tula-logging \
            tula-eigen3 \
            tula-netcdf-cxx4 \
            netcdf-cxx4; do
            grep -F "$required" <<<"$dag"
        done
        for excluded in \
            tula-yaml-cpp \
            tula-csv-parser \
            tula-bitmask \
            tula-meta-enum \
            tula-clipp \
            tula-perflibs \
            tula-grppi \
            ceres-solver; do
            if grep -F "$excluded" <<<"$dag"; then
                echo "NetCDF graph unexpectedly contains ${excluded}" >&2
                exit 1
            fi
        done

        "$spack_cmd" -e "$environment" install \
            --yes-to-all \
            --test=all \
            --overwrite \
            --show-log-on-error

        prefix="$("$spack_cmd" -e "$environment" location -i tula)"
        consumer_build="{{ build_root }}/netcdf-consumer/${compiler}"
        "$spack_cmd" -e "$environment" build-env tula -- \
            cmake --fresh \
                -S "{{ root }}/../tula/tests/netcdf_consumer" \
                -B "$consumer_build" \
                -G Ninja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_PREFIX_PATH="$prefix"
        "$spack_cmd" -e "$environment" build-env tula -- \
            cmake --build "$consumer_build" --parallel
        "$spack_cmd" -e "$environment" build-env tula -- \
            ctest --test-dir "$consumer_build" --output-on-failure
    done

# Verify the CCfits API and its CFITSIO dependency with external and source providers.
tula-ccfits-matrix spack="spack":
    #!/usr/bin/env bash
    set -euo pipefail
    spack_cmd="{{ spack }}"
    environments="{{ root }}/environments/integration/tula_ccfits"

    for case_spec in \
        gcc14_external:external \
        llvm20_external:external \
        gcc14_source:source \
        llvm20_source:source; do
        environment_name="${case_spec%%:*}"
        provider="${case_spec##*:}"
        environment="${environments}/${environment_name}"

        "$spack_cmd" -e "$environment" concretize --force
        dag="$("$spack_cmd" -e "$environment" find -cd)"
        for required in tula-ccfits ccfits cfitsio; do
            grep -F "$required" <<<"$dag"
        done

        # The matrix owns its compiled consumer below. Dependency package test
        # suites are outside this boundary and can be platform-sensitive.
        "$spack_cmd" -e "$environment" install \
            --yes-to-all \
            --test=root \
            --overwrite \
            --show-log-on-error

        for dependency in cfitsio ccfits; do
            prefix="$("$spack_cmd" -e "$environment" location -i "$dependency")"
            if [[ "$provider" == external && "$prefix" != /usr ]]; then
                echo "Expected external ${dependency}, got ${prefix}" >&2
                exit 1
            fi
            if [[ "$provider" == source && "$prefix" == /usr ]]; then
                echo "Expected source-built ${dependency}, got ${prefix}" >&2
                exit 1
            fi
        done

        adapter_prefix="$("$spack_cmd" -e "$environment" location -i tula-ccfits)"
        consumer_build="{{ build_root }}/ccfits-consumer/${environment_name}"
        "$spack_cmd" -e "$environment" build-env tula-ccfits -- \
            cmake --fresh \
                -S "{{ root }}/tests/ccfits_consumer" \
                -B "$consumer_build" \
                -G Ninja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_PREFIX_PATH="$adapter_prefix"
        "$spack_cmd" -e "$environment" build-env tula-ccfits -- \
            cmake --build "$consumer_build" --parallel
        "$spack_cmd" -e "$environment" build-env tula-ccfits -- \
            ctest --test-dir "$consumer_build" --output-on-failure
    done

# Verify GrPPI with and without its optional OpenMP backend.
tula-grppi-matrix spack="spack":
    #!/usr/bin/env bash
    set -euo pipefail
    spack_cmd="{{ spack }}"
    environments="{{ root }}/environments/integration/tula_grppi"

    for case_spec in \
        gcc14_openmp:1 \
        gcc14_no_openmp:0 \
        llvm20_openmp:1 \
        llvm20_no_openmp:0; do
        environment_name="${case_spec%%:*}"
        expected_openmp="${case_spec##*:}"
        environment="${environments}/${environment_name}"
        "$spack_cmd" -e "$environment" concretize --force

        concrete="$("$spack_cmd" -e "$environment" find -c \
            --format '{name}{@version}{variants}' tula)"
        printf '%s\n' "$concrete"
        for enabled in logging enum perflibs grppi; do
            grep -F "+${enabled}" <<<"$concrete"
        done
        if [[ "$expected_openmp" == 1 ]]; then
            grep -F "+openmp" <<<"$concrete"
        else
            grep -F "~openmp" <<<"$concrete"
        fi
        for disabled in yaml ecsv eigen netcdf cli fitting; do
            grep -F "~${disabled}" <<<"$concrete"
        done

        dag="$("$spack_cmd" -e "$environment" find -cd)"
        for required in \
            tula-logging \
            tula-bitmask \
            tula-meta-enum \
            tula-perflibs \
            tula-grppi; do
            grep -F "$required" <<<"$dag"
        done
        for excluded in \
            tula-yaml-cpp \
            tula-csv-parser \
            tula-eigen3 \
            tula-netcdf-cxx4 \
            tula-clipp \
            ceres-solver; do
            if grep -F "$excluded" <<<"$dag"; then
                echo "GrPPI graph unexpectedly contains ${excluded}" >&2
                exit 1
            fi
        done

        "$spack_cmd" -e "$environment" install \
            --yes-to-all \
            --test=all \
            --overwrite \
            --show-log-on-error

        prefix="$("$spack_cmd" -e "$environment" location -i tula)"
        consumer_build="{{ build_root }}/grppi-consumer/${environment_name}"
        "$spack_cmd" -e "$environment" build-env tula -- \
            cmake --fresh \
                -S "{{ root }}/../tula/tests/grppi_consumer" \
                -B "$consumer_build" \
                -G Ninja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_PREFIX_PATH="$prefix" \
                -DEXPECT_OPENMP="$expected_openmp"
        "$spack_cmd" -e "$environment" build-env tula -- \
            cmake --build "$consumer_build" --parallel
        "$spack_cmd" -e "$environment" build-env tula -- \
            ctest --test-dir "$consumer_build" --output-on-failure
    done

# Verify the Ceres-backed fitting component without unrelated Tula features.
tula-fitting-matrix spack="spack":
    #!/usr/bin/env bash
    set -euo pipefail
    spack_cmd="{{ spack }}"
    environments="{{ root }}/environments/integration/tula_fitting"

    for compiler in gcc14 llvm20; do
        environment="${environments}/${compiler}"
        "$spack_cmd" -e "$environment" concretize --force

        concrete="$("$spack_cmd" -e "$environment" find -c \
            --format '{name}{@version}{variants}' tula)"
        printf '%s\n' "$concrete"
        for enabled in logging eigen fitting; do
            grep -F "+${enabled}" <<<"$concrete"
        done
        for disabled in yaml ecsv netcdf enum cli perflibs openmp grppi; do
            grep -F "~${disabled}" <<<"$concrete"
        done

        dag="$("$spack_cmd" -e "$environment" find -cd)"
        for required in tula-logging tula-eigen3 ceres-solver; do
            grep -F "$required" <<<"$dag"
        done
        for excluded in \
            tula-yaml-cpp \
            tula-csv-parser \
            tula-netcdf-cxx4 \
            tula-bitmask \
            tula-meta-enum \
            tula-clipp \
            tula-perflibs \
            tula-grppi; do
            if grep -F "$excluded" <<<"$dag"; then
                echo "Fitting graph unexpectedly contains ${excluded}" >&2
                exit 1
            fi
        done

        "$spack_cmd" -e "$environment" install \
            --yes-to-all \
            --test=all \
            --overwrite \
            --show-log-on-error

        prefix="$("$spack_cmd" -e "$environment" location -i tula)"
        consumer_build="{{ build_root }}/fitting-consumer/${compiler}"
        "$spack_cmd" -e "$environment" build-env tula -- \
            cmake --fresh \
                -S "{{ root }}/../tula/tests/fitting_consumer" \
                -B "$consumer_build" \
                -G Ninja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_PREFIX_PATH="$prefix"
        "$spack_cmd" -e "$environment" build-env tula -- \
            cmake --build "$consumer_build" --parallel
        "$spack_cmd" -e "$environment" build-env tula -- \
            ctest --test-dir "$consumer_build" --output-on-failure
    done

# Build the local-development acceptance chain with GCC 14 and LLVM 20.
acceptance-matrix spack="spack":
    #!/usr/bin/env bash
    set -euo pipefail
    spack_cmd="{{ spack }}"
    acceptance="{{ root }}/environments/acceptance/development"

    run_consumer() {
        local environment="$1"
        local package="$2"
        local repository="$3"
        local compiler="$4"
        local prefix build
        prefix="$("$spack_cmd" -e "$environment" location -i "$package")"
        build="{{ build_root }}/installed-consumers/${compiler}/${repository}"
        mkdir -p "$build"
        "$spack_cmd" -e "$environment" build-env "$package" -- \
            cmake --fresh \
                -S "{{ root }}/../${repository}/tests/installed_consumer" \
                -B "$build" \
                -G Ninja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_PREFIX_PATH="$prefix"
        "$spack_cmd" -e "$environment" build-env "$package" -- \
            cmake --build "$build" --parallel
        "$spack_cmd" -e "$environment" build-env "$package" -- \
            ctest --test-dir "$build" --output-on-failure
    }

    assert_package_tests() {
        local environment="$1"
        local package="$2"
        local count="$3"
        local required_test="$4"
        local prefix log
        prefix="$("$spack_cmd" -e "$environment" location -i "$package")"
        log="${prefix}/.spack/install-time-test-log.txt"
        test -f "$log"
        grep -F \
            "100% tests passed, 0 tests failed out of ${count}" \
            "$log"
        grep -F "$required_test" "$log"
        if grep -F "Skipped" "$log"; then
            echo "${package} package tests contain a skipped case" >&2
            exit 1
        fi
    }

    for compiler in gcc14 llvm20; do
        environment="${acceptance}/${compiler}"
        "$spack_cmd" -e "$environment" concretize --force
        "$spack_cmd" -e "$environment" install \
            --yes-to-all \
            --test=all \
            --overwrite \
            --show-log-on-error
        assert_package_tests \
            "$environment" tula 16 tula::ecsv_reader_real_tunes
        assert_package_tests \
            "$environment" kidscpp 7 \
            kidscpp::ToltecTimeStream.ReadsRealMetadataAndSlice
        assert_package_tests \
            "$environment" citlali 6 \
            citlali::KidsDataProc.PreservesReaderSliceAndSolverBehavior
        run_consumer "$environment" tula tula "$compiler"
        run_consumer "$environment" kidscpp kidscpp "$compiler"
        run_consumer "$environment" citlali citlali "$compiler"
        "$("$spack_cmd" -e "$environment" location -i citlali)/bin/citlali" \
            --version
    done

# Check that packaged deployment profiles retain the accepted portable policy.
deployment-profile-consistency deploy_root="../tolteca_deploy":
    #!/usr/bin/env bash
    set -euo pipefail
    deploy="{{ deploy_root }}"
    test -f "$deploy/pyproject.toml"
    uv run --isolated --with pyyaml python \
        "{{ root }}/tests/check_deployment_profile_alignment.py" \
        --tula-cmake-root "{{ root }}" \
        --deploy-root "$deploy"

# Run the installed Citlali CLI on the complete observation 149101 fixture.
citlali-real-workdir spack="spack" compiler="gcc14":
    #!/usr/bin/env bash
    set -euo pipefail
    spack_cmd="{{ spack }}"
    environment="{{ root }}/environments/acceptance/development/{{ compiler }}"
    workdir="{{ root }}/../tolteca_test_data/tolteca_workdir"
    config="redu/citlali_o149101_0_2_c1.yaml"
    output_root="/tmp/citlali-o149101-output"
    log="{{ build_root }}/citlali-real-workdir/{{ compiler }}.log"

    test -f "$workdir/$config"
    test -f "$workdir/data/apt_149101_matched.ecsv"
    test -e \
        "$workdir/data/toltec0_149101_000_0002_2026_01_19_08_21_50.nc"

    prefix="$("$spack_cmd" -e "$environment" location -i citlali)"
    mkdir -p "$output_root" "$(dirname "$log")"
    (
        cd "$workdir"
        "$prefix/bin/citlali" "$config"
    ) 2>&1 | tee "$log"

    for array in a1100 a1400 a2000; do
        test -n "$(
            find "$output_root" -type f \
                -name "toltec_commissioning_${array}_science_149101_filtered_citlali.fits" \
                -print -quit
        )"
    done

# Build immutable package snapshots without Spack develop paths. Local Git URL
# redirects exercise the exact commits before the recipe revisions are pushed.
snapshot-matrix spack="spack":
    #!/usr/bin/env bash
    set -euo pipefail
    spack_cmd="{{ spack }}"
    snapshots="{{ root }}/environments/acceptance/snapshot/unity"
    workspace="$(dirname "{{ root }}")"

    export GIT_CONFIG_COUNT=4
    export GIT_CONFIG_KEY_0="url.file://${workspace}/tula_cmake.insteadOf"
    export GIT_CONFIG_VALUE_0=https://github.com/toltec-astro/tula_cmake.git
    export GIT_CONFIG_KEY_1="url.file://${workspace}/tula.insteadOf"
    export GIT_CONFIG_VALUE_1=https://github.com/toltec-astro/tula.git
    export GIT_CONFIG_KEY_2="url.file://${workspace}/kidscpp.insteadOf"
    export GIT_CONFIG_VALUE_2=https://github.com/toltec-astro/kidscpp.git
    export GIT_CONFIG_KEY_3="url.file://${workspace}/citlali.insteadOf"
    export GIT_CONFIG_VALUE_3=https://github.com/toltec-astro/citlali.git

    for compiler in gcc14 llvm20; do
        environment="${snapshots}/${compiler}"
        "$spack_cmd" -e "$environment" concretize --force
        export TOLTECA_SPACK_PROFILE="snapshot/unity-${compiler}"
        export TOLTECA_SPACK_LOCK_SHA256
        TOLTECA_SPACK_LOCK_SHA256="$(sha256sum "$environment/spack.lock" | cut -d' ' -f1)"
        "$spack_cmd" -e "$environment" install \
            --yes-to-all \
            --test=all \
            --overwrite \
            --show-log-on-error

        concrete="$("$spack_cmd" -e "$environment" find -clv)"
        printf '%s\n' "$concrete"
        if grep -F "dev_path=" <<<"$concrete"; then
            echo "Release graph unexpectedly contains a develop source" >&2
            exit 1
        fi

        prefix="$("$spack_cmd" -e "$environment" location -i citlali)"
        version="$($prefix/bin/citlali --version 2>&1)"
        printf '%s\n' "$version"
        grep -F "profile=snapshot/unity-${compiler}" <<<"$version"
        grep -F "lock=${TOLTECA_SPACK_LOCK_SHA256}" <<<"$version"
    done

# Build Tlaloc against the minimal Tula ECSV feature set.
tlaloc-matrix spack="spack":
    #!/usr/bin/env bash
    set -euo pipefail
    spack_cmd="{{ spack }}"
    environments="{{ root }}/environments/integration/tlaloc"

    for compiler in gcc14 llvm20; do
        environment="${environments}/${compiler}"
        "$spack_cmd" -e "$environment" concretize --force

        concrete="$("$spack_cmd" -e "$environment" find -c \
            --format '{name}{@version}{variants}' tula)"
        printf '%s\n' "$concrete"
        for enabled in logging yaml ecsv eigen; do
            grep -F "+${enabled}" <<<"$concrete"
        done
        for disabled in netcdf enum cli perflibs openmp grppi fitting; do
            grep -F "~${disabled}" <<<"$concrete"
        done

        dag="$("$spack_cmd" -e "$environment" find -cd)"
        for required in \
            tlaloc \
            tula-logging \
            tula-yaml-cpp \
            tula-csv-parser \
            tula-eigen3 \
            tula-netcdf-cxx4 \
            tlaloc-katcp \
            fftw \
            mariadb-c-client; do
            grep -F "$required" <<<"$dag"
        done
        for excluded in kidscpp ceres-solver; do
            if grep -F "$excluded" <<<"$dag"; then
                echo "Tlaloc graph unexpectedly contains ${excluded}" >&2
                exit 1
            fi
        done

        "$spack_cmd" -e "$environment" install \
            --yes-to-all \
            --test=all \
            --overwrite \
            --show-log-on-error
        "$spack_cmd" -e "$environment" find -clv
        test -x "$environment/.spack-view/bin/tlaloc_clip"
    done
