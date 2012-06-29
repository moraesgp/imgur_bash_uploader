#!/bin/bash

# This script query imgur for an album called $ALBUM_NAME
# if it finds, it returns within a file
# if it doens't find, than it return error code 99

if [ $# -lt 1 ];then
	echo "usage: $0 ALBUM_NAME"
	exit 1
fi

ALBUM_NAME=$1

METHOD=GET

source common_functions.sh

OAUTH_TIMESTAMP=`date  +'%s'`
OAUTH_NONCE=`head -c 300 /dev/urandom | tr -dc A-Za-z0-9 | head -c 30`
DEBUG_FILE=`mktemp --tmpdir=$LOGTEMPDIR ascii_debug_${OAUTH_TIMESTAMP}_XXXXXXX`
HEADERS_N_COOKIES_FILE=`mktemp --tmpdir=$LOGTEMPDIR query_album_header_${OAUTH_TIMESTAMP}_XXXXXXX`
ACCESS_RESOURCES_RESPONSE_BODY=`mktemp --tmpdir=$LOGTEMPDIR query_album_body_${OAUTH_TIMESTAMP}_XXXXXXX`
BASE_STRING_TEMP_FILE=`mktemp --tmpdir=$LOGTEMPDIR base_string_query_album_${OAUTH_TIMESTAMP}_XXXXXXX`

write_parameter oauth_consumer_key ${OAUTH_CONSUMER_KEY}
write_parameter oauth_signature_method ${OAUTH_SIGN_METHOD}
write_parameter oauth_timestamp ${OAUTH_TIMESTAMP}
write_parameter oauth_nonce ${OAUTH_NONCE}
write_parameter oauth_version ${OAUTH_VERSION}
write_parameter oauth_token ${OAUTH_TOKEN}

PARAMETER_STRING=$(create_parameter_string)

BASE_STRING="${METHOD}&`urlencode ${ALBUMS_API_URL}`&"$PARAMETER_STRING

OAUTH_SIGNATURE=`echo -n $BASE_STRING | openssl dgst -sha1 -binary -hmac "${OAUTH_CONSUMER_SECRET}&${OAUTH_TOKEN_SECRET}" | base64`

curl --dump-header $HEADERS_N_COOKIES_FILE --trace-ascii $DEBUG_FILE \
--header "Authorization: OAuth "\
"oauth_consumer_key=\"$OAUTH_CONSUMER_KEY\","\
"oauth_token=\"$OAUTH_TOKEN\","\
"oauth_signature_method=\"$OAUTH_SIGN_METHOD\","\
"oauth_signature=\"`urlencode $OAUTH_SIGNATURE`\","\
"oauth_timestamp=\"$OAUTH_TIMESTAMP\","\
"oauth_nonce=\"$OAUTH_NONCE\","\
"oauth_version=\"$OAUTH_VERSION\"" \
$ALBUMS_API_URL > $ACCESS_RESOURCES_RESPONSE_BODY

RESPONSE_STATUS_LINE=`grep '^HTTP' $HEADERS_N_COOKIES_FILE`

echo $RESPONSE_STATUS_LINE | grep 404

if [ $? -eq 0 ];then
	echo "$0: Got response 404. It means it's the first album beeing created"
	echo "$0: album $ALBUM_NAME not found"
	touch ${LOGTEMPDIR}/${ALBUM_NAME}_${ALBUM_HASH_SUFFIX}
	exit 99
fi

echo $RESPONSE_STATUS_LINE | grep 200

if [ $? -ne 0 ];then
        echo "$0: response status not equal to 200"
        echo "$0: programm will exit"
        exit 1
fi

ALBUM_HASH_TEMP=`xpath -e "/albums/item[title[.=\"$ALBUM_NAME\"]]/id" -q $ACCESS_RESOURCES_RESPONSE_BODY | head -1`

if [ -z "$ALBUM_HASH_TEMP" ];then
	echo "$0: album $ALBUM_NAME not found"
	touch ${LOGTEMPDIR}/${ALBUM_NAME}_${ALBUM_HASH_SUFFIX}
	exit 99
fi

ALBUM_HASH=`echo $ALBUM_HASH_TEMP | perl -npe 's/^<id>(.*)<\/id>.*/$1/'`

echo $ALBUM_HASH > ${LOGTEMPDIR}/${ALBUM_NAME}_${ALBUM_HASH_SUFFIX}

