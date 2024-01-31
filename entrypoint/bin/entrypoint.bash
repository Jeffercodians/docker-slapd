#!/usr/bin/env bash

set -ueo pipefail

ENTRYPOINT_ROOT="${SLAPD_ENTRYPOINT_INSTALL_DIR:-"$(cd "$(dirname "${0}")/.." && pwd)"}"

source "${ENTRYPOINT_ROOT}/lib/libslapd.bash"

error() {
    echo "ERROR: ${1}"
    exit "${2:-"1"}"
}

run_slapd() {
    local -a slapd_flags=()
    local slapd
    slapd="$(slapd.bin)"    || error "Could not find slapd"
    slapd.ensure_data_dir   || error "Could not configure the data directory"
    slapd.ensure_run_dir    || error "Could not configure the run directory"
    slapd.ensure_config_dir || error "Could not configure the config directory"

    # Ensure the ldap libraries from the install can be loaded
    export LD_LIBRARY_PATH
    LD_LIBRARY_PATH="${LD_LIBRARY_PATH-}:$(slapd.lib_path)"

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