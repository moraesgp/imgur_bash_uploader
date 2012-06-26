#!/bin/bash

source imgur_config.sh

if [ ! -d $LOGTEMPDIR ];then
	echo $LOGTEMPDIR  does not exist. Will be created.
	mkdir $LOGTEMPDIR
	if [ $? -ne 0 ];then
		echo could not create $LOGTEMPDIR. Exiting.
		exit 1
	fi
fi

while [ ! -f $ACCESS_TOKEN_FILE ]
do
	echo "$ACCESS_TOKEN_FILE not found. Requesting Access Token now."
	./require_access_token.sh
	if [ $? -ne 0 ];then
		exit 1
	fi
done

source $ACCESS_TOKEN_FILE

./search_pictures.sh

