#!/usr/bin/env bats

set -ueo pipefail

SLAPD_ENTRYPOINT="${BATS_TEST_DIRNAME}/entrypoint.bash"

@test "entrypoint: is executable" {
    [ -e "${SLAPD_ENTRYPOINT}" ]
}
