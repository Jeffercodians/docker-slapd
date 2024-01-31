#!/usr/bin/env bash

set -ueo pipefail

slapd.bin() {
    local slapd="${SLAPD_INSTALL_DIR-}/libexec/slapd"

    [ -e "${slapd}" ] &&
    echo "${slapd}"
}

slapd.lib_path() {
    local slapd_libs="${SLAPD_INSTALL_DIR-}/lib"

    [ -d "${slapd_libs}" ] &&
    echo "${slapd_libs}"
}

slapd.copy_builtin_schema() {
    local schema="${1}"
    local user_schema_dir="${2}"
    local builtin_schema_dir="${SLAPD_INSTALL_DIR}/etc/openldap/schema"

    mkdir -p "${user_schema_dir}" &&
    cp "${builtin_schema_dir}/${schema}.schema" \
        "${builtin_schema_dir}/${schema}.ldif" \
        "${user_schema_dir}"
}

slapd.load_builtin_schema() {
    local schema="${1:-"core"}"
    local user_schema_dir="${SLAPD_CONFIG_DIR}/schema"

    # If the schema already exists, do not override what may be user config
    [ -f "${user_schema_dir}/${schema}.schema" ] ||
    slapd.copy_builtin_schema "${schema}" "${user_schema_dir}"
}

slapd.generate_config() {
    local config_file="${1}"
    local config_template="${SLAPD_CONFIG_INSTALL_DIR}/slapd.conf.tpl"

    envsubst < "${config_template}" > "${config_file}" &&
    chown "${SLAPD_USER}:${SLAPD_GROUP}" "${config_file}" &&

    # There are many available "default schemas" built into the OpenLDAP
    #   installation; we need the core implementation of LDAPv3
    #   (aka RFC2252/RFC2256)
    slapd.load_builtin_schema "core"
}

slapd.config_file() {
    local config_file="${SLAPD_CONFIG_DIR}/slapd.conf"

    [ -f "${config_file}" ] ||
    slapd.generate_config "${config_file}" &&
    echo "${config_file}"
}

slapd.ensure_config_dir() {
    mkdir -p "${SLAPD_CONFIG_DIR}" &&
    chown -R "${SLAPD_USER}:${SLAPD_GROUP}" "${SLAPD_CONFIG_DIR}" &&
    chmod -R o-rwx "${SLAPD_CONFIG_DIR}"
}

slapd.ensure_data_dir() {
    mkdir -p "${SLAPD_DATA_DIR}" &&
    chown -R "${SLAPD_USER}:${SLAPD_GROUP}" "${SLAPD_DATA_DIR}" &&
    chmod -R go-rwx "${SLAPD_DATA_DIR}"
}

slapd.ensure_run_dir() {
    mkdir -p "${SLAPD_RUN_DIR}" &&
    chown -R "${SLAPD_USER}:${SLAPD_GROUP}" "${SLAPD_RUN_DIR}" &&
    chmod -R go-rwx "${SLAPD_RUN_DIR}"
}

slapd.ldap_uri() {
    if [ "${SLAPD_LDAP_PORT_ENABLED}" = "true" ]; then
        echo "ldap://${SLAPD_HOST}:${SLAPD_LDAP_PORT}"
    fi
}

slapd.ldaps_uri() {
    if [ "${SLAPD_LDAPS_PORT_ENABLED}" = "true" ]; then
        echo "ldaps://${SLAPD_HOST}:${SLAPD_LDAPS_PORT}"
    fi
}
