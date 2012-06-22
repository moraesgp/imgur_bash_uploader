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
	./require_access_token.sh
done

source $ACCESS_TOKEN_FILE

echo using
echo "OAUTH_TOKEN: $OAUTH_TOKEN"
echo "OAUTH_TOKEN_SECRET: $OAUTH_TOKEN_SECRET"
echo FINISHED

