#!/bin/bash

if [ $# -lt 1 ];then
	echo "usage: $0 /path/to/picture.jpg [ALBUM_NAME]"
	exit 1
fi


METHOD=POST
FILE_PATH=$1
ALBUM=${2:-NOALBUM}

source common_functions.sh

OAUTH_TIMESTAMP=`date  +'%s'`
OAUTH_NONCE=`head -c 300 /dev/urandom | tr -dc A-Za-z0-9 | head -c 30`
DEBUG_FILE=`mktemp --tmpdir=$LOGTEMPDIR ascii_debug_${OAUTH_TIMESTAMP}_XXXXXXX`
HEADERS_N_COOKIES_FILE=`mktemp --tmpdir=$LOGTEMPDIR access_resources_header_${OAUTH_TIMESTAMP}_XXXXXXX`
ACCESS_RESOURCES_RESPONSE_BODY=`mktemp --tmpdir=$LOGTEMPDIR access_resources_body_${OAUTH_TIMESTAMP}_XXXXXXX`
BASE_STRING_TEMP_FILE=`mktemp --tmpdir=$LOGTEMPDIR base_string_access_resources${OAUTH_TIMESTAMP}_XXXXXXX`

write_parameter oauth_consumer_key ${OAUTH_CONSUMER_KEY}
write_parameter oauth_signature_method ${OAUTH_SIGN_METHOD}
write_parameter oauth_timestamp ${OAUTH_TIMESTAMP}
write_parameter oauth_nonce ${OAUTH_NONCE}
write_parameter oauth_version ${OAUTH_VERSION}
write_parameter oauth_token ${OAUTH_TOKEN}

PARAMETER_STRING=$(create_parameter_string)

echo "parameter string"
echo $PARAMETER_STRING
echo

BASE_STRING="${METHOD}&`urlencode ${IMAGES_API_URL}`&"$PARAMETER_STRING

OAUTH_SIGNATURE=`echo -n $BASE_STRING | openssl dgst -sha1 -binary -hmac "${OAUTH_CONSUMER_SECRET}&${OAUTH_TOKEN_SECRET}" | base64`

echo oauth_signature
echo $OAUTH_SIGNATURE
echo
# --header "Content-Type: application/x-www-form-urlencoded" \

curl --dump-header $HEADERS_N_COOKIES_FILE \
--header "Authorization: OAuth "\
"oauth_consumer_key=\"$OAUTH_CONSUMER_KEY\","\
"oauth_token=\"$OAUTH_TOKEN\","\
"oauth_signature_method=\"$OAUTH_SIGN_METHOD\","\
"oauth_signature=\"`urlencode $OAUTH_SIGNATURE`\","\
"oauth_timestamp=\"$OAUTH_TIMESTAMP\","\
"oauth_nonce=\"$OAUTH_NONCE\","\
"oauth_version=\"$OAUTH_VERSION\"" \
--form image=@${FILE_PATH} \
$IMAGES_API_URL > $ACCESS_RESOURCES_RESPONSE_BODY

grep -i 'HTTP/1.1 200 OK' $HEADERS_N_COOKIES_FILE > /dev/null

if [ $? -ne 0 ];then
	echo "response status not equal to 200"
	grep -i 'Status' $HEADERS_N_COOKIES_FILE
	xpath -e "/error/message" -q $ACCESS_RESOURCES_RESPONSE_BODY | perl -npe 's/^<message>(.*)<\/message>.*/$1/'
	echo "programm will exit"
	exit 1
fi

ERROR_MESSAGE=`xpath -e "/error/message" -q $ACCESS_RESOURCES_RESPONSE_BODY`

if [ -n "$ERROR_MESSAGE" ];then
	echo $ERROR_MESSAGE
	exit 1
fi

PHOTO_HASH=$(xpath -e "/images/image/hash" -q $ACCESS_RESOURCES_RESPONSE_BODY | perl -npe 's/^<hash>(.*)<\/hash>.*/$1/')

echo $PHOTO_HASH >> ${LOGTEMPDIR}/${ALBUM}${ALBUM_FILE_SUFFIX}

