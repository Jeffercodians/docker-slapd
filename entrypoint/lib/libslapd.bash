#!/usr/bin/env bash

set -ueo pipefail

ENTRYPOINT_ROOT="${SLAPD_ENTRYPOINT_INSTALL_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}"
source "${ENTRYPOINT_ROOT}/lib/libslapd_config.bash"

slapd.bin() {
    local slapd="${SLAPD_INSTALL_DIR-}/libexec/slapd"

    [ -e "${slapd}" ] &&
    echo "${slapd}"
}

slapd.lib_path() {
    [ -d "${SLAPD_INSTALL_DIR-}" ] &&
    local slapd_libs="${SLAPD_INSTALL_DIR}/lib" &&

    [ -d "${slapd_libs}" ] &&
    echo "${slapd_libs}"
}

slapd.ldap_uri() {
    if [ "${SLAPD_LDAP_PORT_ENABLED-}" = "true" ]; then
        [ -n "${SLAPD_HOST-}" ] &&
        [ -n "${SLAPD_LDAP_PORT-}" ] &&
        echo "ldap://${SLAPD_HOST}:${SLAPD_LDAP_PORT}"
    fi
}

slapd.ldaps_uri() {
    if [ "${SLAPD_LDAPS_PORT_ENABLED-}" = "true" ]; then
        [ -n "${SLAPD_HOST-}" ] &&
        [ -n "${SLAPD_LDAPS_PORT-}" ] &&
        echo "ldaps://${SLAPD_HOST}:${SLAPD_LDAPS_PORT}"
    fi
}

slapd.ensure_dir() {
    local dir="${1}"

    mkdir -p "${dir}" &&
    chown -R "${SLAPD_USER}:${SLAPD_GROUP}" "${dir}" &&
    chmod -R go-rwx "${dir}"
}

slapd.config_file() {
    local config_file="${SLAPD_CONFIG_DIR}/slapd.conf"

    slapd.ensure_dir "${SLAPD_CONFIG_DIR}" &&
    { [ -f "${config_file}" ] ||
        slapd_config.generate "${config_file}"; } &&
    echo "${config_file}"
}
