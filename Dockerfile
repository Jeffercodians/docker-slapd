ARG DEBIAN_VERSION=12.4-slim

#
# Build the slapd daemon from source to get specific versions
#
FROM debian:${DEBIAN_VERSION} as slapd_builder

ARG INSTALL_BASE_DIR="/opt" \
    BUILD_BASE_DIR="/build" \
    OPENLDAP_VERSION=2.6.6 \
    OPENLDAP_MIRROR="https://www.openldap.org/software/download/OpenLDAP/openldap-release/"

WORKDIR "${BUILD_BASE_DIR}"

RUN apt update && apt install -y \
        build-essential \
        curl \
        groff \
        libtool \
        libssl-dev \
        libwrap0-dev

RUN curl -sL -O "${OPENLDAP_MIRROR}/openldap-${OPENLDAP_VERSION}.tgz" && \
    tar -xvzf "./openldap-${OPENLDAP_VERSION}.tgz" --strip-components 1

RUN ./configure \
        --prefix="${INSTALL_BASE_DIR}" \
        --enable-overlays \
        --enable-ldap \
        --enable-meta \
        --enable-asyncmeta \
        --enable-null \
        --enable-sock \
        --enable-dnssrv \
        --enable-dynacl \
        --enable-aci \
        --enable-modules \
        --enable-rlookups \
        --enable-slapi \
        --enable-alp \
        --enable-wrappers \
        --with-tls=openssl \
        --without-systemd && \
    make depend

RUN make

RUN make test

RUN make install && \
    cp COPYRIGHT LICENSE "${INSTALL_BASE_DIR}"

#
# Entrypoint Script
#
FROM debian:${DEBIAN_VERSION} as entrypoint_builder

ARG INSTALL_BASE_DIR="/opt" \
    BUILD_BASE_DIR="/build"

WORKDIR "${BUILD_BASE_DIR}"

RUN apt update && apt install -y make bats gettext-base

COPY entrypoint/ "${BUILD_BASE_DIR}"

RUN make test

RUN make install INSTALL_PREFIX="${INSTALL_BASE_DIR}"

#
# Debian Backed Runtime
#
FROM debian:${DEBIAN_VERSION} as debian

RUN apt update && apt install -y \
        libtool \
        libssl3 \
        libwrap0 \
        gettext-base && \
    rm -rf /var/lib/apt/* /var/cache/apt/*

ARG INSTALL_BASE_DIR="/opt" \
    SLAPD_LDAP_PORT=389 \
    SLAPD_LDAPS_PORT=686 \
    SLAPD_USER=openldap \
    SLAPD_GROUP=openldap

ENV SLAPD_USER="${SLAPD_USER}" \
    SLAPD_GROUP="${SLAPD_GROUP}" \
    SLAPD_HOST=0.0.0.0 \
    SLAPD_LDAP_PORT=${SLAPD_LDAP_PORT} \
    SLAPD_LDAP_PORT_ENABLED=true \
    SLAPD_LDAPS_PORT=${SLAPD_LDAPS_PORT} \
    SLAPD_LDAPS_PORT_ENABLED=true \
    SLAPD_LDAP_SUFFIX="dc=my-domain,dc=com" \
    SLAPD_CONFIG_DIR=/config \
    SLAPD_DATA_DIR=/data \
    SLAPD_RUN_DIR=/run/slapd \
    SLAPD_INSTALL_DIR="${INSTALL_BASE_DIR}/openldap" \
    SLAPD_ENTRYPOINT_INSTALL_DIR="${INSTALL_BASE_DIR}/entrypoint" \
    SLAPD_CONFIG_INSTALL_DIR="${SLAPD_ENTRYPOINT_INSTALL_DIR}/config"

COPY --from=slapd_builder "${INSTALL_BASE_DIR}" "${SLAPD_INSTALL_DIR}"
COPY --from=entrypoint_builder "${INSTALL_BASE_DIR}" "${SLAPD_ENTRYPOINT_INSTALL_DIR}"

RUN ln -P "${SLAPD_ENTRYPOINT_INSTALL_DIR}/bin/entrypoint.bash" "/entrypoint" && \
    groupadd --system "${SLAPD_GROUP}" && \
    useradd --system --gid "${SLAPD_GROUP}" --no-create-home "${SLAPD_USER}"

EXPOSE ${SLAPD_LDAP_PORT}/tcp \
       ${SLAPD_LDAPS_PORT}/tcp

VOLUME "${SLAPD_CONFIG_DIR}" "${SLAPD_DATA_DIR}"

ENTRYPOINT [ "/entrypoint" ]
