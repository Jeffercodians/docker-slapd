#!/usr/bin/env bash

set -ueo pipefail

source "${BATS_TEST_DIRNAME}/libslapd_config.bash"

setup() {
    [ -n "${BATS_TEST_TMPDIR-}" ] || BATS_TEST_TMPDIR="$(mktemp -d)"

    SLAPD_USER="${UID}"
    SLAPD_GROUP="${GROUPS[0]}"

    SLAPD_CONFIG_DIR="${BATS_TEST_TMPDIR}"

    SLAPD_CONFIG_INSTALL_DIR="${BATS_TEST_TMPDIR}/install"
    mkdir -p "${SLAPD_CONFIG_INSTALL_DIR}"
    cat <<EOF > "${SLAPD_CONFIG_INSTALL_DIR}/slapd.conf.tpl"
database config
EOF

    SLAPD_INSTALL_DIR="${SLAPD_CONFIG_INSTALL_DIR}"
    SLAPD_SCHEMA_DIR="${SLAPD_INSTALL_DIR}/etc/openldap/schema"
    mkdir -p "${SLAPD_SCHEMA_DIR}"
    echo "${RANDOM}" > "${SLAPD_SCHEMA_DIR}/core.schema"
}

teardown() {
    rm -rf "${BATS_TEST_TMPDIR}"
}

@test "slapd_config.generate: generates a slapd.conf from the installed template" {
    local config_file="${SLAPD_CONFIG_DIR}/slapd.conf"

    slapd_config.generate "${config_file}"

    [ -f "${config_file}" ]
    cmp "${config_file}" "${SLAPD_CONFIG_INSTALL_DIR}/slapd.conf.tpl"
    [ "$(stat -c "%u" "${config_file}")" = "${SLAPD_USER}" ]
    [ "$(stat -c "%g" "${config_file}")" = "${SLAPD_GROUP}" ]
}

@test "slapd.config.generate: copys the core.schema into the config dir" {
    local config_file="${SLAPD_CONFIG_DIR}/slapd.conf"

    slapd_config.generate "${config_file}"

    [ -d "${SLAPD_CONFIG_DIR}/schema" ]
    [ -f "${SLAPD_CONFIG_DIR}/schema/core.schema" ]
    cmp "${SLAPD_CONFIG_DIR}/schema/core.schema" "${SLAPD_SCHEMA_DIR}/core.schema"
}