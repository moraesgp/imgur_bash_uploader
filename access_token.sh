#!/bin/bash

source common_functions.sh

METHOD=GET
OAUTH_TIMESTAMP=`date  +'%s'`
OAUTH_NONCE=`head -c 300 /dev/urandom | tr -dc A-Za-z0-9 | head -c 30`
DEBUG_FILE=`mktemp --tmpdir=$LOGTEMPDIR access_token_debug_${OAUTH_TIMESTAMP}_XXXXXXX`
HEADERS_N_COOKIES_FILE=`mktemp --tmpdir=$LOGTEMPDIR access_token_header_${OAUTH_TIMESTAMP}_XXXXXXX`
ACCESS_TOKEN_RESPONSE_BODY=`mktemp --tmpdir=$LOGTEMPDIR access_token_body_${OAUTH_TIMESTAMP}_XXXXXXX`
BASE_STRING_TEMP_FILE=`mktemp --tmpdir=$LOGTEMPDIR base_string_access_token${OAUTH_TIMESTAMP}_XXXXXXX`


write_parameter oauth_consumer_key ${OAUTH_CONSUMER_KEY}
write_parameter oauth_signature_method ${OAUTH_SIGN_METHOD}
write_parameter oauth_timestamp ${OAUTH_TIMESTAMP}
write_parameter oauth_nonce ${OAUTH_NONCE}
write_parameter oauth_version ${OAUTH_VERSION}
write_parameter oauth_token ${OAUTH_TOKEN}

PARAMETER_STRING=$(create_parameter_string)

BASE_STRING="${METHOD}&`urlencode ${ACCESS_TOKEN_URL}`&"$PARAMETER_STRING

OAUTH_SIGNATURE=`echo -n $BASE_STRING | openssl dgst -sha1 -binary -hmac "${OAUTH_CONSUMER_SECRET}&${OAUTH_TOKEN_SECRET}" | base64`

curl --dump-header $HEADERS_N_COOKIES_FILE --trace-ascii $DEBUG_FILE \
--header "Content-Type: application/x-www-form-urlencoded" \
--header "Authorization: OAuth "\
"oauth_consumer_key=\"$OAUTH_CONSUMER_KEY\","\
"oauth_token=\"$OAUTH_TOKEN\","\
"oauth_signature_method=\"$OAUTH_SIGN_METHOD\","\
"oauth_signature=\"`urlencode $OAUTH_SIGNATURE`\","\
"oauth_timestamp=\"$OAUTH_TIMESTAMP\","\
"oauth_nonce=\"$OAUTH_NONCE\","\
"oauth_version=\"$OAUTH_VERSION\"" \
$ACCESS_TOKEN_URL > $ACCESS_TOKEN_RESPONSE_BODY

RESPONSE_STATUS_LINE=`grep '^HTTP' $HEADERS_N_COOKIES_FILE`

echo $RESPONSE_STATUS_LINE | grep 200

if [ $? -ne 0 ];then
	echo "response status not equal to 200"
	echo $RESPONSE_STATUS_LINE | grep 401
	if [ $? -eq 0 ];then
		echo "Error 401 Access Denied"
		echo "You need to authorize access on the web browser"
		exit 2
	else
		echo "There was an error: $RESPONSE_STATUS_LINE"
		exit 1
	fi
fi

OAUTH_TOKEN=`cat $ACCESS_TOKEN_RESPONSE_BODY | perl -npe 's/^.*oauth_token=(.*?)\&.*/$1/'`
OAUTH_TOKEN_SECRET=`cat $ACCESS_TOKEN_RESPONSE_BODY | perl -npe 's/^.*oauth_token_secret=(.*?)$.*/$1/'`

echo "export OAUTH_TOKEN=$OAUTH_TOKEN" >> $ACCESS_TOKEN_DATA
echo "export OAUTH_TOKEN_SECRET=$OAUTH_TOKEN_SECRET" >> $ACCESS_TOKEN_DATA

exit 0

