#!/usr/bin/env bats

set -ueo pipefail

source "${BATS_TEST_DIRNAME}/libslapd.bash"

setup() {
    [ -n "${BATS_TEST_TMPDIR-}" ] || BATS_TEST_TMPDIR="$(mktemp -d)"

    SLAPD_USER="${UID}"
    SLAPD_GROUP="${GROUPS[0]}"

    SLAPD_CONFIG_DIR="${BATS_TEST_TMPDIR}"
    SLAPD_INSTALL_DIR="${BATS_TEST_TMPDIR}"
}

teardown() {
    rm -rf "${BATS_TEST_TMPDIR}"
}

#
# Test Suite
#   slapd.bin: identify slapd binary
#

@test "slapd.bin: prints the path to slapd" {
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

#
# Test Suite
#   slapd.lib: identify slapd library paths
#

@test "slapd.lib_path: prints the path to openldap installed libraries" {
    local slapd_libs_dir="${SLAPD_INSTALL_DIR}/lib"

    mkdir -p "${slapd_libs_dir}"

    run slapd.lib_path

    [ "${output}" = "${slapd_libs_dir}" ]
}

@test "slapd.lib_path: errors when the openldap install cannot be found" {
    unset SLAPD_INSTALL_DIR

    run slapd.lib_path

    [ "${status}" -eq 1 ]
}

#
# Test Suite
#   slapd.ldap_uri
#

@test "slapd.ldap_uri: prints out the ldap URI from the environment when enabled" {
    SLAPD_LDAP_PORT_ENABLED="true"
    SLAPD_HOST="0.0.0.0"
    SLAPD_LDAP_PORT="389"

    run slapd.ldap_uri

    [ "${output}" = "ldap://${SLAPD_HOST}:${SLAPD_LDAP_PORT}" ]
}


@test "slapd.ldap_uri: does not print the URI when not enabled" {
    SLAPD_LDAP_PORT_ENABLED=""

    run slapd.ldap_uri

    [ "${output}" = "" ]
    [ "${status}" -eq 0 ]
}

@test "slapd.ldap_uri: errors when dependent environment values are not set" {
    # With PORT unset
    SLAPD_LDAP_PORT_ENABLED="true"
    SLADP_HOST="0.0.0.0"

    run slapd.ldap_uri

    [ "${status}" -eq 1 ]
    [ "${output}" = "" ]

    # With HOST unset
    unset SLAPD_HOST
    SLAPD_LDAP_PORT="389"

    run slapd.ldap_uri

    [ "${status}" -eq 1 ]
    [ "${output}" = "" ]
}

#
# Test Suite
#   slapd.ldaps_uri
#

@test "slapd.ldaps_uri: prints out the tls ldaps URI from the environment when enabled" {
    SLAPD_LDAPS_PORT_ENABLED="true"
    SLAPD_HOST="0.0.0.0"
    SLAPD_LDAPS_PORT="686"

    run slapd.ldaps_uri

    [ "${output}" = "ldaps://${SLAPD_HOST}:${SLAPD_LDAPS_PORT}" ]
}


@test "slapd.ldaps_uri: does not print the URI when not enabled" {
    SLAPD_LDAPS_PORT_ENABLED=""

    run slapd.ldaps_uri

    [ "${output}" = "" ]
    [ "${status}" -eq 0 ]
}

@test "slapd.ldaps_uri: errors when dependent environment values are not set" {
    # With PORT unset
    SLAPD_LDAPS_PORT_ENABLED="true"
    SLADP_HOST="0.0.0.0"

    run slapd.ldaps_uri

    [ "${status}" -eq 1 ]
    [ "${output}" = "" ]

    # With HOST unset
    unset SLAPD_HOST
    SLAPD_LDAPS_PORT="686"

    run slapd.ldaps_uri

    [ "${status}" -eq 1 ]
    [ "${output}" = "" ]
}

#
# Test Suite
#   slapd.ensure_dir: make a slapd user only directory
#

@test "slapd.ensure_dir: makes a directory only accessible by SLAPD_USER:SLAPD_GROUP" {
    local dir="${BATS_TEST_TMPDIR}/test_dir"

    run slapd.ensure_dir "${dir}"

    [ -d "${dir}" ]
    [ "$(stat -c "%a" "${dir}")" = "700" ]
    [ "$(stat -c "%u" "${dir}")" = "${SLAPD_USER}" ]
    [ "$(stat -c "%g" "${dir}")" = "${SLAPD_GROUP}" ]
}

#
# Test Suite
#   slapd.config_file: generate the slapd config file
#

GENERATED_CONFIG="generated_config"
slapd_config.generate() {
    echo "${GENERATED_CONFIG}" > "${1}"
}

@test "slapd.config_file: should print the config file location" {
    run slapd.config_file

    [ "${output}" = "${SLAPD_CONFIG_DIR}/slapd.conf" ]
}

@test "slapd.config_file: should generate a config file when not present" {
    run slapd.config_file

    [ "$(cat ${output})" = "${GENERATED_CONFIG}" ]
}

@test "slapd.config_file: should replace an existing config file" {
    touch "${SLAPD_CONFIG_DIR}/slapd.conf"

    run slapd.config_file

    [ "$(cat ${output})" = "${GENERATED_CONFIG}" ]
}