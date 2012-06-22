#!/bin/bash

source common_functions.sh

METHOD=GET
OAUTH_TIMESTAMP=`date  +'%s'`
OAUTH_NONCE=`head -c 300 /dev/urandom | tr -dc A-Za-z0-9 | head -c 30`
DEBUG_FILE=`mktemp --tmpdir=$LOGTEMPDIR ascii_debug_${OAUTH_TIMESTAMP}_XXXXXXX`
HEADERS_N_COOKIES_FILE=`mktemp --tmpdir=$LOGTEMPDIR request_token_header_${OAUTH_TIMESTAMP}_XXXXXXX`
REQUEST_TOKEN_RESPONSE_BODY=`mktemp --tmpdir=$LOGTEMPDIR request_token_body_${OAUTH_TIMESTAMP}_XXXXXXX`
BASE_STRING_TEMP_FILE=`mktemp --tmpdir=$LOGTEMPDIR base_string_request_token${OAUTH_TIMESTAMP}_XXXXXXX`

#BASE_STRING="POST&`urlencode ${REQUEST_TOKEN_URL}`&"\
#"oauth_consumer_key`urlencode =${OAUTH_CONSUMER_KEY}`"\
#`urlencode "&oauth_nonce=${OAUTH_NONCE}&oauth_signature_method=${OAUTH_SIGN_METHOD}&oauth_timestamp=${OAUTH_TIMESTAMP}&oauth_version=${OAUTH_VERSION}"`

write_parameter oauth_consumer_key ${OAUTH_CONSUMER_KEY}
write_parameter oauth_signature_method ${OAUTH_SIGN_METHOD}
write_parameter oauth_timestamp ${OAUTH_TIMESTAMP}
write_parameter oauth_nonce ${OAUTH_NONCE}
write_parameter oauth_version ${OAUTH_VERSION}


PARAMETER_STRING=$(create_parameter_string)

echo "parameter string"
echo $PARAMETER_STRING
echo

BASE_STRING="${METHOD}&`urlencode ${REQUEST_TOKEN_URL}`&"$PARAMETER_STRING

echo $BASE_STRING

OAUTH_SIGNATURE=`echo -n $BASE_STRING | openssl dgst -sha1 -binary -hmac "${OAUTH_CONSUMER_SECRET}&" | base64`
echo oauth_signature
echo $OAUTH_SIGNATURE
echo

curl --dump-header $HEADERS_N_COOKIES_FILE --trace-ascii $DEBUG_FILE \
--header "Content-Type: application/x-www-form-urlencoded" \
--header "Authorization: OAuth "\
"oauth_consumer_key=\"$OAUTH_CONSUMER_KEY\","\
"oauth_signature_method=\"$OAUTH_SIGN_METHOD\","\
"oauth_signature=\"`urlencode $OAUTH_SIGNATURE`\","\
"oauth_timestamp=\"$OAUTH_TIMESTAMP\","\
"oauth_nonce=\"$OAUTH_NONCE\","\
"oauth_version=\"$OAUTH_VERSION\"" \
$REQUEST_TOKEN_URL > $REQUEST_TOKEN_RESPONSE_BODY 


RESPONSE_STATUS_LINE=`grep '^HTTP' $HEADERS_N_COOKIES_FILE`

echo $RESPONSE_STATUS_LINE | grep 200

if [ $? -ne 0 ];then
	echo "response status not equal to 200"
	echo "programm will exit"
	exit 1
fi

grep -i 'OAuth Verification Failed' $REQUEST_TOKEN_RESPONSE_BODY > /dev/null

if [ $? -eq 0 ];then
	cat $REQUEST_TOKEN_RESPONSE_BODY
	echo
	exit 1
fi

OAUTH_CALLBACK_ACCEPTED=`cat $REQUEST_TOKEN_RESPONSE_BODY | perl -npe 's/^.*auth_callback_accepted=(.*?)\&.*/$1/'`
OAUTH_TOKEN=`cat $REQUEST_TOKEN_RESPONSE_BODY | perl -npe 's/^.*oauth_token=(.*?)\&.*/$1/'`
OAUTH_TOKEN_SECRET=`cat $REQUEST_TOKEN_RESPONSE_BODY | perl -npe 's/^.*oauth_token_secret=(.*?)\&.*/$1/'`
OAUTH_TOKEN_TTL=`cat $REQUEST_TOKEN_RESPONSE_BODY | perl -npe 's/^.*oauth_token_ttl=(.*?)$.*/$1/'`


echo "export OAUTH_CALLBACK_ACCEPTED=$OAUTH_CALLBACK_ACCEPTED" >> $REQUEST_TOKEN_DATA
echo "export OAUTH_TOKEN=$OAUTH_TOKEN" >> $REQUEST_TOKEN_DATA
echo "export OAUTH_TOKEN_SECRET=$OAUTH_TOKEN_SECRET" >> $REQUEST_TOKEN_DATA
echo "export OAUTH_TOKEN_TTL=$OAUTH_TOKEN_TTL" >> $REQUEST_TOKEN_DATA

