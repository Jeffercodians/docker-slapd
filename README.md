# slapd Docker

Provides an unofficial docker image for [OpenLDAP](https://www.openldap.org/)'s slapd LDAP directory server built from the sources provided by the OpenLDAP project.  The image aims to "dockerize" the LDAP administration process, common configurations can be set entirely from the environment.

## Roadmap

- [x] Docker image builds and runs latest OpenLDAP slapd implementation
- [ ] switch from config files to ldif for slapd startup configurations
- [ ] Image fetches own TLS certificate via ACME
- [ ] slapd extensions built as modules, configure loaded modules with env
- [ ] all extensions/modules built into image (missing sql, argon2, et al)
- [ ] CLI Tool for managing entries\*
- [ ] Option to encrypt database at rest
- [ ] Mount user configurations as addon to builtin config

\* Probably a separate project

# Running the Container

Docker Run for local testing:
```bash
> docker run -name slapd \
    -p 389:389/tcp -p 686:686/tcp \
    -v "./run/config:/config" \
    -v "./run/data:/data" \
    docker.smithery.dev/slapd:latest
```

Docker Compose Up:
```bash
> docker compose up 
```
See [docker-compose.yaml](./docker-compose.yaml) for configuration details

## Environment Variables

Env Name                 | Default Value | Purpose
-------------------------|---------------|---------------------------------------------------
SLAPD_USER               | openldap  | the unix user/UID for the slapd ser ver to run as
SLAPD_GROUP              | openldap  | the unix group/GID for the slapd server to run as
SLAPD_HOST               | 0.0.0.0   | The host for the ldap server to listen on
SLAPD_LDAP_PORT          | 389       | unsecure connections
SLAPD_LDAP_PORT_ENABLED  | true      | When true, enables unsecure TCP listening on the SLAPD_LDAP_PORT
SLAPD_LDPAS_PORT         | 686       | Secure connections via TLS
SLAPD_LDAPS_PORT_ENABLED | true      | When true, enables secure TCP/TLS listening on the SLAPD_LDAPS_PORT
SLAPD_CONFIG_DIR         | /config   | Where built-in LDAP configurations are stored
SLAPD_DATA_DIR           | /data     | Where built-in LDAP configurations are stored

## Volumes

Volume Name | Default Mount | Purpose
------------|---------------|------------------
config      | /config       | Store slapd's configurations and schemas
data        | /data         | Store database files.  Multiple databases will require subdirectories

## Entrypoint

See the [Entrypoint](./entrypoint/README.md) subdirectory for details.

# Building

Build with Docker Compose:
```bash
> docker compose build
```

Build with Docker:
```bash
> docker build .
```

## Build Structure

Component           | Toolchain        | Purpose
--------------------|------------------|-----------------
.env                | Many             | Store default environment variable values for this version of code
Dockerfile          | Docker           | Defines how to build the docker image, including how to build OpenLDAP/slapd from source
docker-compose.yaml | Docker+Compose   | Defines the arguments and context to build and run the slapd image
entrypoint/         | Make, BASH, BATS | Subproject to provide entrypoint scripts to pack into the image.
config/             | Config, LDIF     | Configurations for the slapd service, including schemas, and LDap Interchange Format files for populating the database