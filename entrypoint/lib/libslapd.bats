#!/usr/bin/env bats

set -ueo pipefail

source "${BATS_TEST_DIRNAME}/libslapd.bash"

setup() {
    [ -n "${BATS_TEST_TMPDIR-}" ] || BATS_TEST_TMPDIR="$(mktemp -d)"
}

teardown() {
    rm -rf "${BATS_TEST_TMPDIR}"
}

#
# Test Suite
#   slapd.bin: identify slapd binary
#
@test "slapd.bin: prints the path to slapd" {
    SLAPD_INSTALL_DIR="${BATS_TEST_TMPDIR}"
    local slapd_bin="${SLAPD_INSTALL_DIR}/libexec/slapd"

    mkdir -p "$(dirname "${slapd_bin}")"
    touch "${slapd_bin}"
    chmod +x "${slapd_bin}"

    run slapd.bin

    [ "${output}" = "${slapd_bin}" ]
}

@test "slapd.bin: errors when slapd cannot be found" {
    unset SLAPD_INSTALL_DIR

    run slapd.bin

    [ "${status}" -eq 1 ]
}
