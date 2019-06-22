#!/usr/bin/env bash

set -xe

hash rsync 2>/dev/null || sudo apt-get install -yyq rsync

BACKUP_DRIVE=/media/"$USER"/BU_Drive
BACKUP_DIRECTORY="$BACKUP_DRIVE"/BU_Backups/"$HOSTNAME"
BACKUP_DIRS='/etc /home'
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

apt_backup(){
}

iptables_backup(){
}

cron_backup(){
}

drive_test() {
  if [[ ! $(lsblk -S -o  TRAN | grep 'usb') = *usb* ]]; then
      exit 1
  fi

  if [ ! -d $BACKUP_DRIVE ]; then
      exit 1
  fi
}

default_backup() {
	sudo chown "$user" /media/"$user"/BU_Drive/
  mkdir -p /media/"$user"/BU_Drive/BU_Backups/"$host"
  $RSYNC_CMD $INCLUDE_FILE $EXCLUDE_FILE $BACKUP_DIRS $BACKUP_DIRECTORY
}

drive_test
include_file
exclude_file
default_backup
apt_backup
iptables_backup
cron_backup
