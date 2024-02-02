#!/usr/bin/env bats

set -ueo pipefail

SLAPD_ENTRYPOINT="${BATS_TEST_DIRNAME}/entrypoint.bash"

setup_slapd_install() {
    export SLAPD_INSTALL_DIR="${BATS_TEST_TMPDIR}/install"
    mkdir -p "${SLAPD_INSTALL_DIR}/libexec" "${SLAPD_INSTALL_DIR}/lib"
    MOCK_SLAPD_BIN="${SLAPD_INSTALL_DIR}/libexec/slapd"
    cat <<EOF > "${MOCK_SLAPD_BIN}"
#!/usr/bin/env bash

touch "${MOCK_SLAPD_BIN}.called"
echo " \${*} " > "${MOCK_SLAPD_BIN}.args"

cat <<ENV > "${MOCK_SLAPD_BIN}.envs"
LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}
ENV
EOF
    chmod +x "${MOCK_SLAPD_BIN}"

    export SLAPD_SCHEMA_DIR="${SLAPD_INSTALL_DIR}/etc/openldap/schema"
    mkdir -p "${SLAPD_SCHEMA_DIR}"
    echo "${RANDOM}" > "${SLAPD_SCHEMA_DIR}/core.schema"
}

setup_slapd_config() {
    export SLAPD_CONFIG_INSTALL_DIR="${SLAPD_INSTALL_DIR}/config"
    mkdir -p "${SLAPD_CONFIG_INSTALL_DIR}"
    cp "${BATS_TEST_DIRNAME}/../config/slapd.conf.tpl" \
        "${SLAPD_CONFIG_INSTALL_DIR}/slapd.conf.tpl"
}

setup() {
    [ -n "${BATS_TEST_TMPDIR-}" ] || BATS_TEST_TMPDIR="$(mktemp -d)"

    export SLAPD_USER="${UID}"
    export SLAPD_GROUP="${GROUPS[0]}"
    export SLAPD_HOST="0.0.0.0"
    export SLAPD_LDAP_PORT="389"
    export SLAPD_LDAPS_PORT="686"

    export SLAPD_DATA_DIR="${BATS_TEST_TMPDIR}/data"
    export SLAPD_CONFIG_DIR="${BATS_TEST_TMPDIR}/config"
    export SLAPD_RUN_DIR="${BATS_TEST_TMPDIR}/run"

    export SLAPD_LDAP_SUFFIX="dc=example, dc=com"

    setup_slapd_install
    setup_slapd_config
}

teardown() {
    rm -rf "${BATS_TEST_TMPDIR}"
}

@test "entrypoint: is executable" {
    [ -e "${SLAPD_ENTRYPOINT}" ]
}

@test "entrypoint: runs the installed slapd" {
    "${SLAPD_ENTRYPOINT}"

    [ -f "${MOCK_SLAPD_BIN}.called" ]
}

@test "entrypoint: executes slapd with generated config with values from the environment" {
    "${SLAPD_ENTRYPOINT}"

    local config_file="${SLAPD_CONFIG_DIR}/slapd.conf"

    grep " -f ${config_file} " "${MOCK_SLAPD_BIN}.args"

    grep -E "include[[:space:]]+\"${SLAPD_CONFIG_DIR}/schema/core.schema\"" "${config_file}"
    grep -E "pidfile[[:space:]]+\"${SLAPD_RUN_DIR}/slapd.pid\"" "${config_file}"
    grep -E "suffix[[:space:]]+\"${SLAPD_LDAP_SUFFIX}\"" "${config_file}"
    grep -E "directory[[:space:]]+\"${SLAPD_DATA_DIR}\"" "${config_file}"
}

@test "entrypoint: populates the config with the core schema" {
    "${SLAPD_ENTRYPOINT}"

    [ -f "${SLAPD_CONFIG_DIR}/schema/core.schema" ]
    cmp "${SLAPD_CONFIG_DIR}/schema/core.schema" "${SLAPD_SCHEMA_DIR}/core.schema"
}

@test "entrypoint: executes slapd with the LD_LIBRARY_PATH configured with ldap libraries" {
    "${SLAPD_ENTRYPOINT}"

    unset LD_LIBRARY_PATH

    source "${MOCK_SLAPD_BIN}.envs"

    [[ ":${LD_LIBRARY_PATH}:" == *":${SLAPD_INSTALL_DIR}/lib:"* ]]
}

@test "entrypoint: executes slapd in debug mode with logging" {
    "${SLAPD_ENTRYPOINT}"

    grep " -d 32768 " "${MOCK_SLAPD_BIN}.args"
}

@test "entrypoint: executes slapd with SLAPD_USER and SLAPD_GROUP flags" {
    "${SLAPD_ENTRYPOINT}"

    grep " -u ${SLAPD_USER} " "${MOCK_SLAPD_BIN}.args"
    grep " -g ${SLAPD_GROUP} " "${MOCK_SLAPD_BIN}.args"
}

@test "entrypoint: enables a ldap listener when enabled by the environment" {
    export SLAPD_LDAP_PORT_ENABLED="true"

    "${SLAPD_ENTRYPOINT}"

    grep " -h ldap://${SLAPD_HOST}:${SLAPD_LDAP_PORT} " "${MOCK_SLAPD_BIN}.args"
}

@test "entrypoint: enables a tls ldaps listener when enabled by the environment" {
    export SLAPD_LDAPS_PORT_ENABLED="true"

    "${SLAPD_ENTRYPOINT}"

    grep " -h  ldaps://${SLAPD_HOST}:${SLAPD_LDAPS_PORT} " "${MOCK_SLAPD_BIN}.args"
}

@test "entrypoint: creates and sets strict ownership of the SLAPD_RUN_DIR" {
    "${SLAPD_ENTRYPOINT}"

    [ -d "${SLAPD_RUN_DIR}" ]
    [ "$(stat -c "%a" "${SLAPD_RUN_DIR}")" = "700" ]
    [ "$(stat -c "%u" "${SLAPD_RUN_DIR}")" = "${SLAPD_USER}" ]
    [ "$(stat -c "%g" "${SLAPD_RUN_DIR}")" = "${SLAPD_GROUP}" ]
}

@test "entrypoint: creates and sets strict ownership of the SLAPD_DATA_DIR" {
    "${SLAPD_ENTRYPOINT}"

    [ -d "${SLAPD_DATA_DIR}" ]
    [ "$(stat -c "%a" "${SLAPD_DATA_DIR}")" = "700" ]
    [ "$(stat -c "%u" "${SLAPD_DATA_DIR}")" = "${SLAPD_USER}" ]
    [ "$(stat -c "%g" "${SLAPD_DATA_DIR}")" = "${SLAPD_GROUP}" ]
}

@test "entrypoint: creates and sets strict ownership of the SLAPD_CONFIG_DIR" {
    "${SLAPD_ENTRYPOINT}"

    [ -d "${SLAPD_CONFIG_DIR}" ]
    [ "$(stat -c "%a" "${SLAPD_CONFIG_DIR}")" = "700" ]
    [ "$(stat -c "%u" "${SLAPD_CONFIG_DIR}")" = "${SLAPD_USER}" ]
    [ "$(stat -c "%g" "${SLAPD_CONFIG_DIR}")" = "${SLAPD_GROUP}" ]
}