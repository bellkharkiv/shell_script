#!/bin/bash
RANCHER_SERVER_NAME=$(docker ps -a --format "{{.Image}} {{.Names}}" | grep -i "rancher/rancher" | cut -d' ' -f2)
TODAY_DATE=$(date +%Y%m%d)
RANCHER_COPY_NAME=rancher-data-${TODAY_DATE}
#CREDENTIALS_PATH=~/secrets
BACKUP_PATH=~/home/bell/test/backup
RANCHER_BACKUP_FILE=rancher-data-backup-${TODAY_DATE}.tar.gz
#USE_GDRIVE=0

#if [ "$1" = "--gdrive" ]; then
#
#  if [[ ! -f "${CREDENTIALS_PATH}/token.json" || ! -f "${CREDENTIALS_PATH}/credentials.json" ]]; then
#    echo "[!] Error token.json and/or credentials.json missing in ${CREDENTIALS_PATH}"
#    exit 1
#  fi

#USE_GDRIVE=1
##docker pull d0whc3r/gdrive:latest

#fi

mkdir -p ${BACKUP_PATH}

#docker pull rancher/rancher:latest

docker stop ${RANCHER_SERVER_NAME}
docker create --volumes-from ${RANCHER_SERVER_NAME} --name ${RANCHER_COPY_NAME} rancher/rancher:latest
docker run --rm --volumes-from ${RANCHER_COPY_NAME} -v ${BACKUP_PATH}:/backup:z busybox tar zcf /backup/${RANCHER_BACKUP_FILE} /var/lib/rancher

docker start ${RANCHER_SERVER_NAME}
docker rm -f ${RANCHER_COPY_NAME}

#if [ ${USE_GDRIVE} -eq 1 ]; then
#  docker run --rm -it -v ${BACKUP_PATH}:/backup:ro -v ${CREDENTIALS_PATH}:/app/secrets d0whc3r/gdrive:latest -b /backup/${RANCHER_BACKUP_FILE} -c -f rancher-backup -r -l
#fi
