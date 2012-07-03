#!/bin/bash


if [ ! -d $PHOTO_ROOT_DIR ];then
	echo "$0: Photo directory $PHOTO_ROOT_DIR could not be found"
	echo "$0: Application will exit"
	exit 1
fi

if [ ! -d $MOVE_PHOTO_DIR ];then
	echo "$0: Directory $MOVE_PHOTO_DIR where photos will be moved to does not exist"
	echo "$0: and will be created"
	mkdir -p $MOVE_PHOTO_DIR
	if [ $? -ne 0 ];then
		echo "$0: directory $MOVE_PHOTO_DIR could no be created. Please check"
		exit 1
	fi
fi

source common_functions.sh

CURRENT_DIR=$PHOTO_ROOT_DIR
CURRENT_FILE=""
ALBUM_PHOTO_HASHES=

# starts with dev/null because pictures in the root dir will be uploaded but wont be 
# added to any specific album
arr=("/dev/null")

# Warning! All files and folders on PHOTO_ROOT_DIR will be moved to 
# MOVE_PHOTO_DIR after they are uploaded into imgur

while [ -n "$(ls -A $PHOTO_ROOT_DIR)" ]
do
	# echo "$0: stack: ${arr[@]}"
	CURRENT_FILE=`ls -1Ad $CURRENT_DIR/* 2> /dev/null | head -1`
	if [ -z "$CURRENT_FILE" ];then
		# current directory is empty. Remove it and go to parent directory
		rm -r $CURRENT_DIR
		CURRENT_DIR=`dirname $CURRENT_DIR`
		arr_pop
		continue
	fi
	if [ -d $CURRENT_FILE ];then
		# if current_file is a dir
		CURRENT_DIR=$CURRENT_FILE
		mkdir -p ${MOVE_PHOTO_DIR}${CURRENT_DIR#$PHOTO_ROOT_DIR}
		export ALBUM_PHOTO_HASHES=$(mktemp --tmpdir=$LOGTEMPDIR `basename $CURRENT_DIR`${ALBUM_FILE_SUFFIX}_XXXXXX) 
		arr_push $ALBUM_PHOTO_HASHES
		continue
	else
		echo "$0: FOUND FILE $CURRENT_FILE"
		LAST_INDEX=$(expr ${#arr[@]} - 1)
		./upload_image.sh $CURRENT_FILE `basename $CURRENT_DIR` ${arr[$LAST_INDEX]}
		UPLOAD_IMAGE_RETURN_CODE=$?
		if [ $UPLOAD_IMAGE_RETURN_CODE -eq 0 ];then
			mv $CURRENT_FILE ${MOVE_PHOTO_DIR}${CURRENT_DIR#$PHOTO_ROOT_DIR}
		elif [ $UPLOAD_IMAGE_RETURN_CODE -eq 55 ];then
			echo "$0: Curl returned code 55 for empty response. Happens a lot with imgur. Just retry"
			# since the photo was not moved a simple continue will make it try the last picture again
			continue
		else
			echo "$0: There was a problem with upload_image.sh. Please check"
			exit $UPLOAD_IMAGE_RETURN_CODE
		fi
	fi
done
