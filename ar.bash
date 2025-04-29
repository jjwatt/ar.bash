## @file myarray_ops.bash
## @brief My own interpretation of different operations on bash arrays
##
## @detail Some of these are based on examples in the bash repo, but
## they're bash 4.3+ because they use namerefs and other newer
## features of bash.
##

## @fn ar:shift()
## @brief Like shift, but for arrays
ar::shift() {
    local -n arr="$1"
    local -i n
    case $# in
	1)	n=1 ;;
	2)	n=$2 ;;
	*)	echo "$FUNCNAME: usage: $FUNCNAME array [count]" >&2
		return 2;;
    esac
    local arr_len="${#arr[@]}"
    # If shift count is more than array length, return empty array
    if (( n > arr_len )); then
	arr=()
	return 0
    fi
    arr=("${arr[@]:"$n"}")
}


## @fn ar::push()
## @brief Appends remaining arguments to array name
## @param arrayname The name of the array to push onto
## @param rest val1 [val2 {...} ] Values to push onto the array
ar::push() {
    local -n arr="$1"
    shift
    arr+=("$@")
}

ar::append() {
    ar::push "$@"
}

## @fn ar::pop1()
## @brief Removes and returns the last element of an array
## @param arrayname The name of the array to pop from
ar::pop1() {
    (( $# != 1 )) && {
	"$FUNCNAME: usage: $FUNCNAME arrayname"
	return 2
    }

    local -n arr="$1"
    local -i arr_len="${#arr[@]}"
    if (( arr_len <= 0 )); then
	echo "" >&2
	return 0
    fi
    local -i i=$((arr_len - 1))
    local popped="${arr[i]}"
    arr=("${arr[@]:0:$i}")
    echo "$popped"
}

## @fn ar::pop()
## @brief Removes and returns one element (defaults to last)
## @detail Like Python's list pop()
##  Usage: ar::pop array [index]
ar::pop() {
    (( $# < 1 )) && {
	echo "$FUNCNAME: usage: $FUNCNAME arrayname [index]" >&2
	return 2
    }
    local -n arr="$1"
    local -i index
    local -i arr_len="${#arr[@]}"
    (( arr_len == 0 )) && return 1

    # Determine the index to pop.
    if [[ -z "$2" ]]; then
	# No index provided, so pop from the end.
	index=$((arr_len - 1))
    else
	index="$2"
	# Handle negative indexing like Python.
	if (( index < 0 )); then
	    index=$((arr_len + index))
	fi
	if (( index < 0 || index >= arr_len )); then
	    echo "Error: index out of bounds" >&2
	    return 1
	fi
    fi
    local popped="${arr[index]}"
    local -a pre=("${arr[@]:0:$index}")
    local -a post=("${arr[@]:$((index + 1))}")
    arr=("${pre[@]}" "${post[@]}")
    echo "$popped"
}

## @fn ar::extend()
## @brief Extend the first array by appending all items from the second array
## @detail Like Python's list.extend()
## Usage: ar:extend array1 array2
ar::extend() {
    (( $# < 2 )) && {
	echo "$FUNCNAME: usage: $FUNCNAME arrayname1 arrayname2" >&2
	return 2
    }
    local -n arr="$1"
    local -n arr2="$2"
    arr=("${arr[@]}" "${arr2[@]}")
}


## @fn ar::insert()
## @brief Insert an item at given position
## @param arrayname The name of the array to act on
## @param index The index of the element before which to insert
## @param item The item to insert
ar::insert() {
    (( $# != 3 )) && {
	echo "$FUNCNAME: usage: $FUNCNAME arrayname index item" >&2
	return 2
    }
    local -n arr="$1"
    local -i index="$2"
    if ! [[ $index =~ ^-?[0-9]+$ ]]; then
	echo "Error: index must be an integer" >&2
	return 2
    fi
    local item="$3"

    local -a pre=("${arr[@]:0:$index}")
    local -a post=("${arr[@]:$((index))}")
    arr=("${pre[@]}" "$item" "${post[@]}")
    return 0
}


## @fn ar::reverse()
## @brief Reverse array stored in arr in-place
## @detail My simplification of Chris Ramey's reverse from bash examples
## For bash 4.3+, uses namerefs
## Usage: ar::reverse arrayname
ar::reverse() {
    local -n arr="$1"
    local -i i
    local arr_len temp

    # Get arr_len
    arr_len="${#arr[@]}"

    # Reverse array by swapping first half with second half.
    for ((i=0; i < arr_len/2; i++ )); do
	temp="${arr[i]}"
	arr[i]="${arr[arr_len-i-1]}"
	arr[arr_len-i-1]="$temp"
    done
}

# @fn array_to_string
# @brief Turn an array into a string with seperator
# @param vname_of_array The variable name of the array
# @param vname_of_string The variable name of the string
# @param separator The optional separator to use. Defaults to IFS
ar::array_to_string() {
    (( ($# < 2) || ($# > 3) )) && {
	echo "$FUNCNAME: usage: $FUNCNAME arrayname stringname [seperator]" >&2
	return 2
    }
    local array=$1 string=$2
    (($#==3)) && [[ $3 = ? ]] && local IFS="${3}${IFS}"
    
    eval $string="\"\${$array[*]}\""
    return 0
}

# @fn string_to_array
# @brief Turn a string into an array with a specified delimiter
# @param vname_of_string The variable name of the string
# @param vname_of_array The variable name of the array
# @param delimiter The optional delimiter to use. Defaults to space.
ar::string_to_array() {
    (( ($# < 2) || ($# > 3) )) && {
	echo "$FUNCNAME: usage: $FUNCNAME arrayname stringname [delimiter]"
	return 2
    }
    local string="$1" array="$2"
    (($#==3)) && [[ $3 = ? ]] && local IFS="${3}"

    eval read -ra "$array" <<< "${!string}"
    return 0
}

