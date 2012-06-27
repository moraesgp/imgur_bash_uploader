#!/bin/bash

source imgur_config.sh

if [ ! -d $LOGTEMPDIR ];then
	echo "$0: $LOGTEMPDIR  does not exist. Will be created."
	mkdir -p $LOGTEMPDIR
	if [ $? -ne 0 ];then
		echo "$0: could not create $LOGTEMPDIR. Exiting."
		exit 1
	fi
fi

TIMESTAMP=`date  +'%s'`
export REQUEST_TOKEN_DATA=`mktemp --tmpdir=$LOGTEMPDIR request_token_data_${TIMESTAMP}_XXXXXXX`

./request_token.sh

if [ $? -ne 0 ];then
	echo "$0: There was a problem acquiring request token. Exiting"
	exit 1
fi

source $REQUEST_TOKEN_DATA

if [ $OAUTH_CALLBACK_ACCEPTED -ne 1 ];then
        echo "$0: Callback returned $OAUTH_CALLBACK_ACCEPTED. It should be 1"
        echo "$0: exiting"
        exit 1
fi

echo "Please open your favorite web browser and access"
echo "${AUTHORIZE_URL}?oauth_token=$OAUTH_TOKEN" 
echo "and sign in to allow application on your account"
echo
read -p "Press Enter when done"

TIMESTAMP=`date  +'%s'`
export ACCESS_TOKEN_DATA=`mktemp --tmpdir=$LOGTEMPDIR access_token_data_${TIMESTAMP}_XXXXXXX`

./access_token.sh

ACCESS_TOKEN_RETURN_CODE=$?

while [ $ACCESS_TOKEN_RETURN_CODE -ne 0 ]
do
	echo "Please open your favorite web browser and access"
	echo "${AUTHORIZE_URL}?oauth_token=$OAUTH_TOKEN" 
	echo "and sign in to allow application on your account"
	echo
	read -p "Press Enter when done"
	./access_token.sh
	ACCESS_TOKEN_RETURN_CODE=$?
done

cp $ACCESS_TOKEN_DATA $ACCESS_TOKEN_FILE

echo "$0: file $ACCESS_TOKEN_FILE successfuly created and ready to use"

exit 0


