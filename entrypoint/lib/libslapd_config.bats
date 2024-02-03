#!/usr/bin/env bash

set -ueo pipefail

source "${BATS_TEST_DIRNAME}/libslapd_config.bash"

setup() {
    [ -n "${BATS_TEST_TMPDIR-}" ] || BATS_TEST_TMPDIR="$(mktemp -d)"

    SLAPD_USER="${UID}"
    SLAPD_GROUP="${GROUPS[0]}"
    SLAPD_LDAP_SUFFIX="dc=example,dc=com"

    SLAPD_DATA_DIR="#{BATS_TEST_TMPDIR}/data"
    SLAPD_RUN_DIR="#{BATS_TEST_TMPDIR}/run"
    SLAPD_CONFIG_DIR="${BATS_TEST_TMPDIR}"
    SLAPD_CONFIG_FILE="${SLAPD_CONFIG_DIR}/slapd.conf"

    SLAPD_INSTALL_DIR="${BATS_TEST_TMPDIR}/install"
    SLAPD_SCHEMA_DIR="${SLAPD_INSTALL_DIR}/etc/openldap/schema"
    mkdir -p "${SLAPD_SCHEMA_DIR}"
    echo "${RANDOM}" > "${SLAPD_SCHEMA_DIR}/core.schema"
}

teardown() {
    rm -rf "${BATS_TEST_TMPDIR}"
}

@test "slapd_config.generate: generates a slapd.conf from the installed template" {
    slapd_config.generate "${SLAPD_CONFIG_FILE}"

    [ -f "${SLAPD_CONFIG_FILE}" ]
    [ "$(stat -c "%u" "${SLAPD_CONFIG_FILE}")" = "${SLAPD_USER}" ]
    [ "$(stat -c "%g" "${SLAPD_CONFIG_FILE}")" = "${SLAPD_GROUP}" ]
}

@test "slapd_config.generate: copys the core.schema into the config dir" {
    slapd_config.generate "${SLAPD_CONFIG_FILE}"

    [ -d "${SLAPD_CONFIG_DIR}/schema" ]
    [ -f "${SLAPD_CONFIG_DIR}/schema/core.schema" ]
    cmp "${SLAPD_CONFIG_DIR}/schema/core.schema" "${SLAPD_SCHEMA_DIR}/core.schema"
}

@test "slapd_config.generate: adds include line to config for core schema" {
    slapd_config.generate "${SLAPD_CONFIG_FILE}"

    grep -E "include[[:space:]]+\"${SLAPD_CONFIG_DIR}/schema/core.schema\"" "${SLAPD_CONFIG_FILE}"
}

@test "slapd_config.generate: sets up a config database" {
    slapd_config.generate "${SLAPD_CONFIG_FILE}"

    grep -E "database[[:space:]]+config" "${SLAPD_CONFIG_FILE}"
}

@test "slapd.config.generate: sets up the core mdb database using the environment" {
    slapd_config.generate "${SLAPD_CONFIG_FILE}"

    local mdb_args_file="${BATS_TEST_TMPDIR}/mdb.args"
    grep -A10 -E "database[[:space:]]+mdb" "${SLAPD_CONFIG_FILE}" > "${mdb_args_file}"

    grep -E "suffix[[:space:]]+\"${SLAPD_LDAP_SUFFIX}\"" "${mdb_args_file}"
    # Should default to 1 gb of memory
    grep -E "maxsize[[:space:]]+$((1024 * 1024 * 1024))" "${mdb_args_file}"
    grep -E "directory[[:space:]]+\"${SLAPD_DATA_DIR}\"" "${mdb_args_file}"
    grep -E "index[[:space:]]+objectClass eq" "${mdb_args_file}"
}

@test "slapd_config.generate: consumes the rootpw from the file specified in env" {
    SLAPD_ROOTDN_SECRET_FILE="${BATS_TEST_TMPDIR}/rootpw"
    local test_password="${RANDOM}"
    echo "${test_password}" > "${SLAPD_ROOTDN_SECRET_FILE}"

    slapd_config.generate "${SLAPD_CONFIG_FILE}"

    local mdb_args_file="${BATS_TEST_TMPDIR}/mdb.args"
    grep -A10 -E "database[[:space:]]+mdb" "${SLAPD_CONFIG_FILE}" > "${mdb_args_file}"

    grep -E "rootpw[[:space:]]+\"${test_password}\"" "${mdb_args_file}"
}

@test "slapd_config.generate: configures the pidfile" {
    slapd_config.generate "${SLAPD_CONFIG_FILE}"

    grep -E "pidfile[[:space:]]+\"${SLAPD_RUN_DIR}/slapd.pid\"" "${SLAPD_CONFIG_FILE}"

}