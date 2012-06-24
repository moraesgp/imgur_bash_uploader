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
ALBUM_NAME="${BASE_ALBUM_FILE_NAME%%_photo_to_album*}"

echo ALBUM NAME: $ALBUM_NAME

PHOTO_HASH_LIST=

while read photo_hash
do
	PHOTO_HASH_LIST=$PHOTO_HASH_LIST`echo -n "${photo_hash},"`
done < $ALBUM_FILE_NAME

PHOTO_HASH_LIST=${PHOTO_HASH_LIST%?}
echo PHOTO_HASH_LIST:  $PHOTO_HASH_LIST
