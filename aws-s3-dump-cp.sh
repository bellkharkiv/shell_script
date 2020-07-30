#!/bin/bash
ARCHIVE=$2
DIR_REST="$(cd "${PWD}"; pwd)"
ENV_FILE="${DIR_REST}/.env"
TMP_DIR="/tmp/dash-backup"
S3_DUMP_DIR="${TMP_DIR}/s3"
case $1 in
    --backup)
        [[ -d "${DIR_REST}" ]] && echo "Directory ${DIR_REST} found."  ||  echo "Directory "${DIR_REST}" not found."
        [[ -f "${ENV_FILE}" ]] && source ${ENV_FILE} || echo "File "${ENV_FILE}" not found."
        [[ ! -d "${TMP_DIR}" ]] && echo -n "Creating dyrectory "${TMP_DIR}" for backup..." && mkdir "${TMP_DIR}" && echo "OK."
        [[ ! -d "${S3_DUMP_DIR}" ]] && echo -n "Creating dyrectory "${S3_DUMP_DIR}" for backup files from S3 bucket..." && mkdir "${S3_DUMP_DIR}" && echo "OK."
        echo -n "Copy files from S3 bucket "${AWS_S3_BUCKET}"..."
            aws s3 cp --recursive s3://${AWS_S3_BUCKET} ${S3_DUMP_DIR} && echo "OK." || echo "Error creating dump - $?"
        echo "Create database dump..."
            mongodump --uri="${MONGODB_URI}" -o ${TMP_DIR} && echo "OK." || echo "Error creating dump - $?"
        echo "Archive data from S3 backet and database dump..."
            DATE=$(date +%d-%m-%Y-%H%M)
            cd ${TMP_DIR}
            tar --exclude="./dash-dump-${DATE}.tar.gz" -czvf dash-dump-${DATE}.tar.gz ./ && echo "OK."
        echo -n "Get ORG viriable..."
            ORG=$(mongo ${MONGODB_URI} --quiet --eval "db.getCollection('organizations').find({}).forEach(printjson)" | grep -v "ISODate" | jq -r '._coreId' |cut -d\: -f 3) && echo "OK."
        echo -n "Create S3 bucket for save archive "
            aws s3 mb s3://dash-backup-${ORG} --region ${AWS_REGION} && echo "OK."
        echo -n "Move archive to S3 bucket..."
            aws s3 cp dash-dump-${DATE}.tar.gz s3://dash-backup-${ORG} && echo "OK."
        echo -n "Removing tmp data..."
            rm -rf ${TMP_DIR} dash-dump-${DATE}.tar.gz && echo "OK."
        ;;
    --restore)
        [[ -d "${DIR_REST}" ]] && echo "Directory ${DIR_REST} found."  ||  echo "Directory "${DIR_REST}" not found."
        [[ ! -d "${TMP_DIR}" ]] && echo "Creating dyrectory "${TMP_DIR}" for backup." && mkdir "${TMP_DIR}"
        [[ -f "${ENV_FILE}" ]] && source ${ENV_FILE} || echo "File "${ENV_FILE}" not found."
        echo -n "Get ORG viriable..."
            ORG=$(mongo ${MONGODB_URI} --quiet --eval "db.getCollection('organizations').find({}).forEach(printjson)" | grep -v "ISODate" | jq -r '._coreId' |cut -d\: -f 3) && echo "OK."
        echo "Download archive from S3 bucket..."
            cd ${TMP_DIR}
            aws s3 cp s3://dash-backup-${ORG}/${ARCHIVE} . && echo "OK."
        echo "Unarchiving..."
            tar -xzvf ${ARCHIVE} && echo "OK."
        echo "Upload files to S3 bucket..."
            aws s3 cp --recursive s3/ s3://${AWS_S3_BUCKET} && echo "OK."
        echo "Restore database data..."
            NAME_MONGO_DB=$(ls ${TMP_DIR} | egrep -v "(s3|${ARCHIVE})")
            mongorestore --drop --uri="${MONGODB_URI}" -d ${NAME_MONGO_DB} ${NAME_MONGO_DB}/
            cd ${DIR_REST}
            npm run migrate
        echo "Removing tmp data..."
            rm -rf ${TMP_DIR} && echo "OK."
        echo "Restart rest and rest-agenda..."
            pm2 restart rest-agenda && pm2 restart rest
        ;;
    * )
        echo "                                                                              "
        echo "      Please follow the instructions below.                                   "
        echo "          For Backup data need enter next data:                               "
        echo "             1) Enter \"--backup\" for backup action.                         "
        echo "                                                                              "
        echo "          For Restore data need enter next data:                              "
        echo "             1) Enter \"--restore\" for restore action.                       "
        echo "             2) Enter version archive from s3 bucket which need restore.      "
        echo "                                                                              "
esac
