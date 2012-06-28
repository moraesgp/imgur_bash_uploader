#!/bin/bash

if [ $# -lt 1 ];then
        echo usage: $0 ALBUM_PHOTO_FILE_PATH
        exit 1
fi

ALBUM_FILE_NAME=$1
if [ ! -f $ALBUM_FILE_NAME ];then
        echo $0: Could not find file $ALBUM_FILE_NAME
        exit 1
fi

BASE_ALBUM_FILE_NAME=`basename $ALBUM_FILE_NAME`

ALBUM_NAME=${BASE_ALBUM_FILE_NAME%${ALBUM_FILE_SUFFIX}*}
ALBUM_NAME=`basename $ALBUM_NAME`

./query_album.sh $ALBUM_NAME
QUERY_ALBUM_RETURN_VALUE=$?

ALBUM_HASH=

if [ $QUERY_ALBUM_RETURN_VALUE -eq 99 ];then
	echo "$0: Album $ALBUM_NAME does not exist. It will be created now"
	./create_album.sh $ALBUM_NAME
elif [ $QUERY_ALBUM_RETURN_VALUE -ne 0 ];then
	echo "$0: There was a problem. Exiting"
	exit 1
fi

ALBUM_HASH=$(cat ${LOGTEMPDIR}/${ALBUM_NAME}_${ALBUM_HASH_SUFFIX})

if [ -z "$ALBUM_HASH" ];then
	echo "$0: Empty album hash. Something went wrong. Exiting"
	exit 1
fi

PHOTO_HASH_LIST=

while read photo_hash
do
        PHOTO_HASH_LIST=$PHOTO_HASH_LIST`echo -n "${photo_hash},"`
done < $ALBUM_FILE_NAME

PHOTO_HASH_LIST=${PHOTO_HASH_LIST%?}

echo "$0: ALBUM_FILE_NAME: $ALBUM_FILE_NAME"
echo "$0: ALBUM_NAME: $ALBUM_NAME"
echo "$0: ALBUM_HASH: $ALBUM_HASH"
echo "$0: PHOTO_HASH_LIST: $PHOTO_HASH_LIST"

# At this point we have $ALBUM_FILE_NAME, $ALBUM_NAME, $ALBUM_HASH and $PHOTO_HASH_LIST

METHOD=POST

source common_functions.sh

OAUTH_TIMESTAMP=`date  +'%s'`
OAUTH_NONCE=`head -c 300 /dev/urandom | tr -dc A-Za-z0-9 | head -c 30`
DEBUG_FILE=`mktemp --tmpdir=$LOGTEMPDIR add_images_to_album_${OAUTH_TIMESTAMP}_XXXXXXX`
HEADERS_N_COOKIES_FILE=`mktemp --tmpdir=$LOGTEMPDIR add_images_to_album_header_${OAUTH_TIMESTAMP}_XXXXXXX`
ACCESS_RESOURCES_RESPONSE_BODY=`mktemp --tmpdir=$LOGTEMPDIR add_images_to_album_body_${OAUTH_TIMESTAMP}_XXXXXXX`
BASE_STRING_TEMP_FILE=`mktemp --tmpdir=$LOGTEMPDIR add_images_to_album_base_string${OAUTH_TIMESTAMP}_XXXXXXX`

write_parameter oauth_consumer_key ${OAUTH_CONSUMER_KEY}
write_parameter oauth_signature_method ${OAUTH_SIGN_METHOD}
write_parameter oauth_timestamp ${OAUTH_TIMESTAMP}
write_parameter oauth_nonce ${OAUTH_NONCE}
write_parameter oauth_version ${OAUTH_VERSION}
write_parameter oauth_token ${OAUTH_TOKEN}
write_parameter title ${ALBUM_NAME}
write_parameter add_images ${PHOTO_HASH_LIST}

PARAMETER_STRING=$(create_parameter_string)

BASE_STRING="${METHOD}&`urlencode ${ALBUMS_API_URL}/${ALBUM_HASH}`&"$PARAMETER_STRING

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
--data "title=${ALBUM_NAME}" \
--data "add_images=$PHOTO_HASH_LIST" \
${ALBUMS_API_URL}/${ALBUM_HASH} > $ACCESS_RESOURCES_RESPONSE_BODY

RESPONSE_STATUS_LINE=`grep '^HTTP' $HEADERS_N_COOKIES_FILE`

echo $RESPONSE_STATUS_LINE | grep 200

if [ $? -ne 0 ];then
	echo "response status not equal to 200"
	echo "programm will exit"
	exit 1
fi

exit 0

