#!/usr/bin/env bash

RSYNC_CMD='sudo rsync -aH --delete --info=progress2'

exclude_file(){
	if [ ! -f 'bu.exclude' ]; then
		EXCLUDE_FILE="--exclude-from=bu.exclude"
	else
		EXCLUDE_FILE=""
	fi
}

include_file(){
	if [ ! -f 'bu.include' ]; then
		INCLUDE_FILE="--files-from=bu.include"
	else
		INCLUDE_FILE=""
	fi
}

include_file
exclude_file

echo $RSYNC_CMD $INCLUDE_FILE $EXCLUDE_FILE
