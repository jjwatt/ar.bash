#!/usr/bin/env bats
# shellcheck disable=SC2317
## @file test_ar.bats
## @brief Tests for ar.bash, a simple array lib for bash

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
    # Put os_upgrade_oneshot.sh in the path
    PATH="${DIR}/../:$PATH"
}

