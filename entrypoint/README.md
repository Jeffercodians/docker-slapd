# slapd Docker Entrypoint

Starts the slapd daemon with the configurations set by the docker environment.

## Roadmap

- [x] Starts slapd in the foreground with stdout logging
- [x] Protects slapd files with strict file permissions
- [x] Generates initial config from a template using environment values

# Running

The entrypoint script the entrypoint for the slapd docker image.  See the [slapd Docker](../README.md) for more details.

# Building & Testing

Ensure `bats` and `make` are available on the build machine.  To run all tests:
```bash
> make test
```