## @file myarray_ops.bash
## @brief My own interpretation of different operations on bash arrays
##
## @detail Some of these are based on examples in the bash repo, but
## they're bash 4.3+ because they use namerefs and other newer
## features of bash.
##

## @fn ar:shift()
## @brief Like shift, but for arrays
## @detail Remove n items from the end of the array
## @param arrayname [n]
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


## @fn ar::append()
## @brief Appends remaining arguments to array name
## @param arrayname The name of the array to push onto
## @param rest val1 [val2 {...} ] Values to push onto the array
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
## @detail Like Python's list.extend(). The first array is modified in-place.
## Usage: ar:extend array1 array2
ar::extend() {
    (( $# < 2 )) && {
	echo "$FUNCNAME: usage: $FUNCNAME arrayname1 arrayname2" >&2
	return 2
    }
    local -n arr="$1"
    local -n arr2="$2"
    for item in "${arr2[@]}"; do
	arr+=( "$item" )
    done
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
    local item="$3"
    if ! [[ $index =~ ^-?[0-9]+$ ]]; then
	echo "Error: index must be an integer" >&2
	return 2
    fi

    local arr_len="${#arr[@]}"

    # Handle negative indexing like Python.
    if (( index < 0 )); then
	index=$(( arr_len + index ))
	# If it's still negative, insert at beginning.
	# I think this is what Python does.
	if (( index < 0 )); then
	    index=0
	fi
    fi
    # Like Python, see if it goes over arr_len,
    # and just insert at the end if it does.
    if (( index > arr_len )); then
	index=arr_len
    fi
    local -a pre=("${arr[@]:0:$index}")
    local -a post=("${arr[@]:$((index))}")
    arr=("${pre[@]}" "$item" "${post[@]}")
    return 0
}


## @fn ar::index()
## @brief Return the index of the first item in array whose needle is equal to the given value.
## @detail Like Python's list.index(x[, start[, end]])
## Usage: ar::index arrayname needle [start [end]]
ar::index() {
    local -n arr="$1"
    local needle="$2"
    local start="${3:-0}"
    local end="$4"
    local -i arr_len="${#arr[@]}"

    (( $# < 2 || $# > 4)) && {
	echo "$FUNCNAME: usage: $FUNCNAME arrayname needle [start [end]]" >&2
	return 2
    }

    # Try to treat negative indexes the way Python does.
    if (( start < 0 )); then
	start=$((arr_len + start))
	if (( start < 0 )); then
	    start=0
	fi
    fi

    if [[ -n $end  && $end -lt 0 ]]; then
	end=$((arr_len + end))
    fi

    # Set default end if not provided.
    [[ -z $end ]] && end="$arr_len"

    # Make sure start and end are within bounds.
    if (( start < 0 || start > arr_len )); then
	echo "Value error: substring index out of range" >&2
	return 2
    fi
    if (( end < 0 || end > arr_len )); then
	echo "Value error: substring index out of range" >&2
	return 2
    fi

    # Iterate through the specified range.
    for ((i=start; i < end; i++)); do
	if [[ ${arr[$i]} == "$needle" ]]; then
	    echo "$i"
	    return 0
	fi
    done

    # We didn't find the needle
    echo "Value error: '$needle' not found" >&2
    return 1
}


## @fn ar::remove()
## @brief Remove the first occurrence of value from array
## @detail Like Python's list.remove(x)
## Usage: ar::remove arrayname value
ar::remove() {
    local -n arr="$1"
    local needle="$2"
    local -i arr_len="${#arr[@]}"

    (( $# != 2 )) && {
	echo "$FUNCNAME: usage: $FUNCNAME arrayname value" >&2
	return 2
    }

    local -i remove_index
    remove_index="$(ar::index "$1" "$needle")"
    # If needle is not in the array, ar::index will return non-zero
    ret="$?"
    if ! ((ret == 0)); then
	return "$ret"
    fi

    local -a pre=("${arr[@]:0:$remove_index}")
    local -a post=("${arr[@]:$((remove_index + 1))}")
    arr=("${pre[@]}" "${post[@]}")
    return 0
}

ar::clear() {
    local -n arr="$1"
    arr=()
}

## @fn ar::count()
## @brief Return the number of times value appears in the array
## @detail Like Python's list.count(x)
## Usage: ar::count arrayname
ar::count() {
    local -n arr="$1"
    local needle="$2"
    local -i count=0

    # Simple linear search
    for value in "${arr[@]}"; do
	if [[ $value == $needle ]]; then
	   (( count++ ))
	fi
    done
    if (( count == 0 )); then
	echo 0
	return 1
    fi
    echo "$count"
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


## @fn ar::set()
## @brief Turn array into a set array (no duplicates)
## @param arr The array to setify
## @param arr_set The array to write the result into
ar::set() {
    local -n arr="$1"
    local -A assoc
    local -n arr_set="$2"
    for val in "${arr[@]}"; do
	assoc[$val]=1
    done
    arr_set=("${!assoc[@]}")
}


## @fn ar::set_in()
## @brief Set membership
## @param arr The array to search
## @param needle The value to search for
ar::in_set() {
    local -n arr="$1"
    local -A assoc
    for val in "${arr[@]}"; do
	assoc[$val]=1
    done
    [[ -v assoc["$2"] ]]
}


## @fn ar::union()
## @brief The union of two sets
## @detail Write the union of two sets to the third varname
## @param arr1 The first array
## @param arr2 The second array
## @param union_set The resulting union array
ar::union() {
  local -n arr1="$1"
  local -n arr2="$2"
  local -n union_set="$3"
  local -A union_assoc

  for val in "${arr1[@]}"; do
    union_assoc[$val]=1
  done

  for val in "${arr2[@]}"; do
    union_assoc[$val]=1
  done

  union_set=("${!union_assoc[@]}")
}


## @fn ar::punion()
## @brief Print the union of two arrays
## @detail Can be captured as an array with res=($(punion arr1 arr2))
## @param arr1 The first array
## @param arr2 The second array
ar::punion() {
  local -n arr1="$1"
  local -n arr2="$2"
  local -A union_assoc
  local -a union_set

  for val in "${arr1[@]}"; do
    union_assoc[$val]=1
  done

  for val in "${arr2[@]}"; do
    union_assoc[$val]=1
  done

  union_set=("${!union_assoc[@]}")
  echo "${union_set[@]}"
}


## @fn ar::intersection
## @brief The intersection of two arrays
## @detail
## @param arr1 The first array name
## @param arr2 The second array name
## @params intersect_arr The array name to write the result to
ar::intersection() {
    echo "Not Implemented Yet"
    local -n arr1="$1"
    local -n arr2="$2"
    local -n intersect_arr="$3"
    local -A assoc1
    local -A intersect_assoc

    for val in "${arr1[@]}"; do
	assoc1["$val"]=1
    done
    for val in "${arr2[@]}"; do
	if [[ -v assoc1["$val"] ]]; then
	    intersect_assoc["$val"]=1
	fi
    done
    intersect_arr=("${!intersect_assoc[@]}")
}


## @fn array_to_string
## @brief Turn an array into a string with seperator
## @param vname_of_array The variable name of the array
## @param vname_of_string The variable name of the string
## @param separator The optional separator to use. Defaults to IFS
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
