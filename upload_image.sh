#!/bin/bash

if [ $# -lt 3 ];then
	echo "usage: $0 /path/to/picture.jpg ALBUM_NAME ALBUM_PHOTOS_HASH_LIST"
	exit 1
fi

METHOD=POST
FILE_PATH=$1
ALBUM=$2
ALBUM_PHOTO_HASHES=$3

source common_functions.sh

OAUTH_TIMESTAMP=`date  +'%s'`
OAUTH_NONCE=`head -c 300 /dev/urandom | tr -dc A-Za-z0-9 | head -c 30`
DEBUG_FILE=`mktemp --tmpdir=$LOGTEMPDIR ascii_debug_${OAUTH_TIMESTAMP}_XXXXXXX`
HEADERS_N_COOKIES_FILE=`mktemp --tmpdir=$LOGTEMPDIR upload_image_header_${OAUTH_TIMESTAMP}_XXXXXXX`
ACCESS_RESOURCES_RESPONSE_BODY=`mktemp --tmpdir=$LOGTEMPDIR upload_image_body_${OAUTH_TIMESTAMP}_XXXXXXX`
BASE_STRING_TEMP_FILE=`mktemp --tmpdir=$LOGTEMPDIR base_string_upload_image${OAUTH_TIMESTAMP}_XXXXXXX`

write_parameter oauth_consumer_key ${OAUTH_CONSUMER_KEY}
write_parameter oauth_signature_method ${OAUTH_SIGN_METHOD}
write_parameter oauth_timestamp ${OAUTH_TIMESTAMP}
write_parameter oauth_nonce ${OAUTH_NONCE}
write_parameter oauth_version ${OAUTH_VERSION}
write_parameter oauth_token ${OAUTH_TOKEN}

PARAMETER_STRING=$(create_parameter_string)

BASE_STRING="${METHOD}&`urlencode ${IMAGES_API_URL}`&"$PARAMETER_STRING

OAUTH_SIGNATURE=`echo -n $BASE_STRING | openssl dgst -sha1 -binary -hmac "${OAUTH_CONSUMER_SECRET}&${OAUTH_TOKEN_SECRET}" | base64`

curl --dump-header $HEADERS_N_COOKIES_FILE -sS \
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

CURL_RETURN_VALUE=$?

echo "$0: CURL_RETURN_VALUE: $CURL_RETURN_VALUE (0 is good)"

if [ $CURL_RETURN_VALUE -eq 55 ];then
	exit $CURL_RETURN_VALUE
fi

grep -i 'HTTP/1.1 200 OK' $HEADERS_N_COOKIES_FILE > /dev/null

if [ $? -ne 0 ];then
	echo "$0: response status not equal to 200"
	grep -i 'Status' $HEADERS_N_COOKIES_FILE
	if [ -s $ACCESS_RESOURCES_RESPONSE_BODY ];then
		xpath -e "/error/message" -q $ACCESS_RESOURCES_RESPONSE_BODY | perl -npe 's/^<message>(.*)<\/message>.*/$1/'
	else
		echo "$0: file $ACCESS_RESOURCES_RESPONSE_BODY has zero byte"
	fi
	echo "$0: programm will exit"
	exit 1
fi

ERROR_MESSAGE=`xpath -e "/error/message" -q $ACCESS_RESOURCES_RESPONSE_BODY`

if [ -n "$ERROR_MESSAGE" ];then
	echo $ERROR_MESSAGE
	exit 1
fi

PHOTO_HASH=$(xpath -e "/images/image/hash" -q $ACCESS_RESOURCES_RESPONSE_BODY | perl -npe 's/^<hash>(.*)<\/hash>.*/$1/')

echo $PHOTO_HASH >> $ALBUM_PHOTO_HASHES

