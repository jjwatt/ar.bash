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

@test "ar::pop removes and returns an element from the end of the array" {
    ar::pop _starting_array
    [[ "${#_starting_array[@]}" == 2 ]]
}

@test "ar::index returns the index for the first occurence of value" {
    local i
    i="$(ar::index _starting_array sausage)"
    [[ $i -eq 2 ]]
}

@test "ar::index returns 1 if the value is not in the array" {
    run ar::index _starting_array beef
    [[ $status -eq 1 ]]
}

@test "ar::index returns non-zero if an array index is out of bounds" {
    run ar::index _starting_array rice 4
    [[ $status -eq 2 ]]
}

@test "ar::extend appends items from the second array to the first array" {
    local _second_array=(onions celery garlic)
    ar::extend _starting_array _second_array
    [[ "${_starting_array[*]}" == "rice beans sausage onions celery garlic" ]]
}

@test "ar::remove removes the first occurence of value from the array" {
    ar::remove _starting_array rice
    [[ "${_starting_array[*]}" == "beans sausage" ]]
}

@test "ar::remove fails with non-zero rc if value does not exist" {
    run ar::remove _starting_array beef
    assert_failure
}

@test "ar::count returns the number of times value appears in array" {
    run ar::count _starting_array "rice"
    assert_success
    assert_output "1"

    local _another_array=(rice beans rice sausage)
    run ar::count _another_array "rice"
    assert_success
    assert_output "2"
}

@test "ar::reverse reverses an array in-place" {
    local _starting_array=(rice beans sausage)
    local _expected_reversed_array=(sausage beans rice)
    ar::reverse _starting_array
    assert_equal "${_starting_array[*]}" "${_expected_reversed_array[*]}"
}

@test "ar::set turns an array into a set array" {
    local expected_arr=(rice beans sausage)
    local expected_len="${#expected_arr[@]}"
    local starting_arr=(rice beans sausage rice)
    local -a set_arr
    ar::set starting_arr set_arr
    local len="${#set_arr[@]}"
    (( len == expected_len ))
    # Order shouldn't matter
    for ((i=0; i < arr_len; i++)); do
	ar::in_set expected_arr "${set_arr[i]}"
    done
}

@test "ar::union writes the union of two sets to a third var" {
    local -a first_arr=(rice beans sausage)
    local -a second_arr=(beef onions)
    local -i first_len="${#first_arr[@]}"
    local -i second_len="${#second_arr[@]}"
    local -i combined_len=$(( first_len + second_len ))
    local -i i
    local -a union_arr
    ar::union first_arr second_arr union_arr
    assert_equal "$combined_len" 5
    for ((i=0; i < first_len; i++)); do
	ar::in_set union_arr "${first_arr[i]}"
	[[ $status -eq 0 ]]
    done
    for ((i=0; i < second_len; i++)); do
	ar::in_set union_arr "${second_arr[i]}"
	[[ $status -eq 0 ]]
    done
}

@test "ar::intersection writes the intersection of two sets to a third var" {
    local -a first_arr=(rice beans sausage)
    local -a second_arr=(rice beef onions)
    local -a intersection_arr
    ar::intersection first_arr second_arr intersection_arr
    assert_equal "${intersection_arr[0]}" "rice"
}

@test "ar::difference writes the set difference of two sets to a third var" {
    local -a first_arr=(rice beans sausage)
    local -a second_arr=(rice beef onions)
    local -a expected_diff=(beans sausage)
    local -a diff_arr
    ar::difference first_arr second_arr diff_arr
    assert_equal "${diff_arr[*]}" "${expected_diff[*]}"
}

@test "ar::symmetric_difference writes the symmetric set difference of two sets to a third var" {
    local -a first_arr=(rice beans sausage)
    local -a second_arr=(rice beef onions)
    local -a expected_diff=(beans sausage beef onions)
    local -a diff_arr
    ar::symmetric_difference first_arr second_arr diff_arr
    # Order shouldn't matter
    local -i expected_len="${#expected_diff[@]}"
    local -i actual_len="${#diff_arr[@]}"
    assert_equal "$expected_len" "$actual_len"
    for ((i=0; i < expected_len; i++)); do
	ar::in_set diff_arr "${expected_diff[i]}"
    done
}
