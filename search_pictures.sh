#!/bin/bash

set -x

if [ ! -d $PHOTO_ROOT_DIR ];then
	echo Photo directory $PHOTO_ROOT_DIR could not be found
	echo Application will exit
	exit 1
fi

if [ ! -d $MOVE_PHOTO_DIR ];then
	echo Directory $MOVE_PHOTO_DIR where photos will be moved to does not exist
	echo and will be created
	mkdir -p $MOVE_PHOTO_DIR
	if [ $? -ne 0 ];then
		echo directory $MOVE_PHOTO_DIR could no be created. Please check
		exit 1
	fi
fi

CURRENT_DIR=$PHOTO_ROOT_DIR
CURRENT_FILE=""

# Warning! All files and folders on PHOTO_ROOT_DIR will be moved to 
# MOVE_PHOTO_DIR after they are uploaded into imgur

while [ -n "$(ls -A $PHOTO_ROOT_DIR)" ]
do
	# read -p pause
	CURRENT_FILE=`ls -1Ad $CURRENT_DIR/* 2> /dev/null | head -1`
	if [ -z "$CURRENT_FILE" ];then
		# current directory is empty. Remove it and go to parent directory
		rm -r $CURRENT_DIR
		CURRENT_DIR=`dirname $CURRENT_DIR`
		continue
	fi
	if [ -d $CURRENT_FILE ];then
		# if current_file is a dir
		CURRENT_DIR=$CURRENT_FILE
		mkdir -p ${MOVE_PHOTO_DIR}${CURRENT_DIR}
		continue
	else
		echo FOUND FILE $CURRENT_FILE
		echo RIGHT HERE GONNA UPLOAD FILE $CURRENT_FILE
		# place photo upload command here
		mv $CURRENT_FILE ${MOVE_PHOTO_DIR}${CURRENT_DIR}
	fi
done
