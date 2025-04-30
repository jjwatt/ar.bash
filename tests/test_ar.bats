#!/usr/bin/env bats
# shellcheck disable=SC2317
## @file test_ar.bats
## @brief Tests for ar.bash, a simple array lib for bash

setup() {
    load 'test_helper/bats-support/load.bash'
    load 'test_helper/bats-assert/load.bash'
    DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
    # Put os_upgrade_oneshot.sh in the path
    PATH="${DIR}/../:$PATH"
    . ar.bash
    _starting_array=(rice beans sausage)
}

@test "ar::shift removes an item from the end of the array" {
    ar::shift _starting_array
    [[ "${#_starting_array[@]}" == 2 ]]
}

@test "ar::shift arrayname n removes n items from the end of the array" {
    ar::shift _starting_array 2
    [[ "${#_starting_array[@]}" == 1 ]]
}

@test "ar::push arrayname items pushes items to the end of the array" {
    local expected=(rice beans sausage ham)
    ar::push _starting_array ham
    arr_len="${#_starting_array[@]}"
    local -i i
    for ((i=0; i < arr_len; i++)); do
	[[ ${_starting_array[i]} == "${expected[i]}" ]]
    done
    ar::push _starting_array salt pepper
    ar::push expected salt pepper
    for ((i=0; i < arr_len; i++)); do
	[[ ${_starting_array[i]} == "${expected[i]}" ]]
    done    
}

@test "ar::remove removes the first occurence of value from the array" {
    ar::remove _starting_array rice
    [[ "${_starting_array[*]}" == "beans sausage" ]]
}

@test "ar::remove fails with non-zero rc if value does not exist" {
    run ar::remove _starting_array beef
    [[ $status -eq 1 ]]
}
