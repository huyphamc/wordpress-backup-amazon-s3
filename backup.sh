#!/bin/bash

set -e

backup_dir="/backup/sites"
log="/backup/backup-log"
logname="prod-bkup-daily"
site_dir="/var/www/html/wptest"
site_name="wptest"

set $(date)
#date=`date --iso`
date=`date +%Y-%m-%d`

# Amazon Credentials
AWS_BUCKETNAME="huytestbucket"
older_days="7"

# create working folder
mkdir -p $backup_dir/$site_name
mkdir -p $log

# MySQL Information
MYSQL_DATABASE="wptest"
MYSQL_USER="huypham"
MYSQL_PASSWORD="test@1234"

# backup database
/usr/bin/mysqldump --add-drop-table ${MYSQL_DATABASE} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} > /$backup_dir/$site_name/${MYSQL_DATABASE}.sql


# backup source code
tar czPf $backup_dir/$site_name/${site_name}_$date.tar.gz  $site_dir


echo "Backup was done on $date" >> $log/$logname-$date.log

# copy file
s3cmd put --recursive --delete-removed /$backup_dir/$site_name s3://${AWS_BUCKETNAME}/$date/

# cleanup
rm -Rf /$backup_dir/*

# Delete backup older x days
s3cmd ls s3://$AWS_BUCKETNAME | while read -r line;
  do

    folderLink=`echo $line|awk {'print $2'}`
    folderDate=`date -d "$(basename $folderLink)" +%s`
    sevendays=$(date --date="${older_days} day ago" +"%Y-%m-%d")
    compareDate=`date -d "$sevendays" +%s`
    if [ $folderDate -le $compareDate ]; then
	s3cmd del --recursive "$folderLink"
    fi
  done;
