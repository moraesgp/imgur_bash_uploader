#!/bin/bash

function write_parameter() {
	echo `urlencode $1`=`urlencode $2` >> $BASE_STRING_TEMP_FILE
}


function create_parameter_string() {
	STRING=""
	while read line
	do
		STRING=$STRING`echo -n "${line}&"`
	done < <(sort $BASE_STRING_TEMP_FILE)

	STRING=${STRING%&*}
	STRING=`urlencode $STRING`
	echo $STRING

}

arr_push() {
	arr=("${arr[@]}" "$1")
}

arr_pop() {
	i=$(expr ${#arr[@]} - 1)
	placeholder=${arr[$i]}
	unset arr[$i]
	arr=("${arr[@]}")
}

