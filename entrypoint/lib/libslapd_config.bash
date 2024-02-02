#!/usr/bin/env bash

set -ueo pipefail

slapd_config.load_builtin_schema() {
    local schema="${1:-"core"}"
    local user_schema_dir="${SLAPD_CONFIG_DIR}/schema"

    # If the schema already exists, do not override what may be user config
    [ -f "${user_schema_dir}/${schema}.schema" ] || {
        local builtin_schema_dir="${SLAPD_INSTALL_DIR}/etc/openldap/schema"

        mkdir -p "${user_schema_dir}" &&
        cp "${builtin_schema_dir}/${schema}.schema" "${user_schema_dir}"
    }
}

slapd_config.generate() {
    local config_file="${1}"
    local config_template="${SLAPD_CONFIG_INSTALL_DIR}/slapd.conf.tpl"

    envsubst < "${config_template}" > "${config_file}" &&
    chown "${SLAPD_USER}:${SLAPD_GROUP}" "${config_file}" &&

    # There are many available "default schemas" built into the OpenLDAP
    #   installation; we need the core implementation of LDAPv3
    #   (aka RFC2252/RFC2256)
    slapd_config.load_builtin_schema "core"
}
