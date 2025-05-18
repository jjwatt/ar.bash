# Source the library
. "../ar.bash"

max() {
    local -i _first="$1"
    local -i _second="$2"
    if (( _second > _first)); then
	echo "$_second"
    else
	echo "$_first"
    fi
}

## @fn longest_consecutive()
## @brief Return the count of the longest consecuritve string of numbers
longest_consecutive() {
    local -a _arr=("$@")
    local -a _arr_set
    local -i cur
    local -i cnt=0
    local -i res=0
    # Setify array
    ar::set _arr _arr_set
    for val in "${_arr[@]}"; do
	if ar::in_set _arr_set "$val" && ! ar::in_set _arr_set $(( val - 1 )); then
	    cur="$val"
	    cnt=0
	    while ar::in_set _arr_set "$cur"; do
		# Remove number to avoid recomputation
		ar::remove _arr_set "$cur"
		(( cur++ ))
		(( cnt++ ))
	    done
	    # Update optimal length
	    res="$(max "$res" "$cnt")"
	fi
    done
    echo "$res"
}

main() {
    echo "$(longest_consecutive 2 6 1 9 4 5 3)"
}

main "$@"
