#!/usr/bin/env bash

error() {
    echo "ERROR: ${1}"
    exit "${2:-"1"}"
}

slapd.bin() {
    local slapd="${SLAPD_INSTALL_DIR}/libexec/slapd"

    [ -e "${slapd}" ] &&
    echo "${slapd}"
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

run_slapd() {
    local -a slapd_flags=()
    local slapd
    slapd="$(slapd.bin)"    || error "Could not find slapd"
    slapd.ensure_data_dir   || error "Could not configure the data directory"
    slapd.ensure_run_dir    || error "Could not configure the run directory"
    slapd.ensure_config_dir || error "Could not configure the config directory"

    # Force slapd to run in the foreground by setting debug mode.
    #   Note: (-d)ebug 32768 results in logging messages at the configured
    #       log level
    #   For further reading See running slapd:
    #       https://www.openldap.org/doc/admin24/runningslapd.html
    slapd_flags+=(-d 32768)

    # Set the User/UID and Group/GID for the running slapd process to give
    #   the runner of the container full control over how the data is stored
    slapd_flags+=(-u "${SLAPD_USER}" -g "${SLAPD_GROUP}")

    # Use a slapd config file even though it is not recommended to give the
    #   dockerized context more idempotency.
    # Note: Dynamic configs can still be loaded via ldif files, but on each
    #   start the main slapd.conf file will be respected
    slapd_flags+=(-f "$(slapd.config_file)") || \
        error "Could not generate initial configuration file"

    # Only expose the endpoints as configurd in the environment variables
    #   to give the runner of the container full control over how the slapd
    #   server listens on the network
    slapd_flags+=(-h "$(slapd.ldap_uri) $(slapd.ldaps_uri)") || \
        error "Could not identify enpoint URIs"

    echo "Begin slapd (OpenLDAP Daemon):"

    # Running slapd with exec passes interrupts directly to slapd
    exec "${slapd}" "${slapd_flags[@]}"
}

run_slapd