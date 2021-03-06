#!/bin/bash

source imgur_config.sh

if [ ! -d $LOGTEMPDIR ];then
	echo $LOGTEMPDIR  does not exist. Will be created.
	mkdir $LOGTEMPDIR
	if [ $? -ne 0 ];then
		echo could not create $LOGTEMPDIR. Exiting.
		exit 1
	fi
fi

while [ ! -f $ACCESS_TOKEN_FILE ]
do
	echo "$ACCESS_TOKEN_FILE not found. Requesting Access Token now."
	./require_access_token.sh
	if [ $? -ne 0 ];then
		exit 1
	fi
done

source $ACCESS_TOKEN_FILE

# Search for pictures and upload one by one
# It alsos saves the files hashes returned by imgur into a specific file
# this specific file will be used later to create an album with the directorys name and include
# the images into that album

./search_pictures.sh

EXIT_CODE_01=$?
if [ $EXIT_CODE_01 -ne 0 ];then
	echo "$0: There was a problem. Check log"
	echo "$0: ERROR_CODE $EXIT_CODE_01"
	# Note: script could exit here but I chose not to
	# so it has a chance to add uploaded photos to their albums
fi


# after all pictures are inserted the next script will do the following:
# 1) find files with ALBUM_FILE_SUFFIX - those file have the album name and 
#      the images hashes that should be inserted into that album
# 2) query imgur for the album name
# 2a) if album exists than get the album's hash
# 2b) if album does not exist than create and get the newly created album's hash
# 3) insert pictures hash within the file into that album
# 4) mark file as COMPLETED so it doesn't get run again
# 5) pickup the next album file and continue 

ALBUM_FILE_IMGs_HASH=$(ls -1tr ${LOGTEMPDIR}/*${ALBUM_FILE_SUFFIX}* 2> /dev/null | grep -v COMPLETED | head -1)
                
while [ -n "$ALBUM_FILE_IMGs_HASH" ]
do      
        echo "$0: working album file  $ALBUM_FILE_IMGs_HASH"
	if [ -s "$ALBUM_FILE_IMGs_HASH" ];then
		./add_images_to_album.sh $ALBUM_FILE_IMGs_HASH
		EXIT_CODE_02=$?
		if [ $EXIT_CODE_02 -eq 0 ];then
		        mv $ALBUM_FILE_IMGs_HASH ${ALBUM_FILE_IMGs_HASH}_COMPLETED
		else
			echo "$0: Problem including images into album. Please check"
			echo "$0: ERROR_CODE $EXIT_CODE_02"
			break
		fi
	else
		echo "$0: file $ALBUM_FILE_IMGs_HASH has zero byte. Skipping"
		mv $ALBUM_FILE_IMGs_HASH ${ALBUM_FILE_IMGs_HASH}_COMPLETED
	fi
        ALBUM_FILE_IMGs_HASH=$(find $LOGTEMPDIR -name "*${ALBUM_FILE_SUFFIX}*" -not -name "*COMPLETED" -print | head -1)
done

EXIT_CODE=0
# if at least one of the exit_codes is non-zero the sum should also be non-zero
(( EXIT_CODE = EXIT_CODE_01 + EXIT_CODE_02 ))

exit $EXIT_CODE

