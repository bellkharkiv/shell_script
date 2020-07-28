#!/usr/bin/env bash

MONGO_DATABASES="you mongo-instances"

MONGO_HOST="127.0.0.1"
MONGO_PORT="27017"
TIMESTAMP=`date +\%Y\%m\%d-\%H\%M`

for db in $MONGO_DATABASES
do
  BACKUPS_DIR="/home/ec2-user/backups/$db"
  BACKUP_NAME="$db-$TIMESTAMP"

  /usr/bin/mongodump --username superadmin \
    --password *********** \
    --authenticationDatabase admin \
    -d $db

  mkdir -p $BACKUPS_DIR
  mv dump $BACKUP_NAME
  tar -zcvf $BACKUPS_DIR/$BACKUP_NAME.tar.gz $BACKUP_NAME
  rm -rf $BACKUP_NAME

  if [ -f $BACKUPS_DIR/$BACKUP_NAME.tar.gz ]
  then
    aws s3 cp $BACKUPS_DIR/$BACKUP_NAME.tar.gz s3://backup/mongo/
    rm -rf $BACKUPS_DIR
  else
    echo "Dump does not exists."
  fi
done
