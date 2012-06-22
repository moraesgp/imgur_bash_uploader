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

