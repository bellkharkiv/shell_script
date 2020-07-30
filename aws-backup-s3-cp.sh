#!/bin/bash
export AWS_PROFILE_PROD=***
export AWS_PROFILE_DEV=***

DATE=$(date +%Y%m%d)
DAY=7
BACKUPS_DIR_PROD="/backups/prod/iq-mongo-backups/${DATE}"
BACKUPS_DIR_DEV="/backups/dev/iconiq-backups/${DATE}"

if [ -d $BACKUPS_DIR_PROD ]
then
    echo "Directory already exists"
else
    mkdir -p $BACKUPS_DIR_PROD
fi

if [ -d $BACKUPS_DIR_DEV ]
then
    echo "Directory already exists"
else
    mkdir -p $BACKUPS_DIR_DEV
fi

LASTDATE_PROD=$(aws s3 ls s3://iq-mongo-backups/production/ --profile ${AWS_PROFILE_PROD} | grep ${DATE} | awk '{print $4}')
for ARH in $LASTDATE_PROD
do
PATH=/usr/bin:/usr/local/bin aws s3 cp s3://iq-mongo-backups/production/${ARH} --profile ${AWS_PROFILE_PROD} $BACKUPS_DIR_PROD
done

LASTDATE_DEV=$(aws s3 ls s3://iconiq-backup/mongo/ --profile ${AWS_PROFILE_DEV} | grep ${DATE} | awk '{print $4}')
for ARH in $LASTDATE_DEV
do
PATH=/usr/bin:/usr/local/bin aws s3 cp s3://iconiq-backup/mongo/${ARH} --profile ${AWS_PROFILE_DEV} $BACKUPS_DIR_DEV
done

find /backups/prod/iq-mongo-backups/* -type d -mtime +${DAY} -exec rm -rf {} \;
find /backups/dev/iconiq-backups/* -type d -mtime +${DAY} -exec rm -rf {} \;
