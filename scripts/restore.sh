#!/bin/bash


#!/bin/bash

set -e

LOGFILE="/opt/restore/restore-info.log"
LOCKFILE="/opt/restore/restore.lock"
RESTORE_DIR="/opt/restore/"
DUMP_DIR="/opt/restore/dump"
BINARY_DIR="/opt/restore/binary"
STATUSFILE="/opt/restore/restore-status"
MYSQL_USER=root
MYSQL_PASS=root
MYSQL_HOST=restore-db
ALERT_EMAILS="alerts@example.com"
DATABASES=( employees )

# Generate a timestamp to name the backup files with.
TS=$(date +%F)


function log (){
        echo "[$(date +%y%m%d-%H:%M:%S)] $1" >> ${LOGFILE}
}

function setAlertFlag () {
	      echo $1 > ${STATUSFILE}
}

function downloadCloud () {
        if [ -d "${DUMP_DIR}" ]; then
              /bin/rm -rf ${DUMP_DIR}
        fi
        
        mkdir -p ${DUMP_DIR}/schemas
        mkdir -p ${DUMP_DIR}/data

        log "Downloading schemas backups from the cloud..."
        aws s3 sync s3://${S3_BUCKET}/schemas/${TS} ${DUMP_DIR}/schemas
        log "Done."

        log "Downloading data backups from the cloud..."
        aws s3 sync s3://${S3_BUCKET}/data/${TS} ${DUMP_DIR}/data
        log "Done."
}

function restore () {
  log "Restoring databases..."
  for db in ${DATABASES}; do
    log "Creating empty database ${db}..."
    mysql -u${MYSQL_USER} -p${MYSQL_PASS} -h${MYSQL_HOST} -e "create database ${db};"
  done

  for file in $DATABASES; do
    log "Restoring backups ..."
    for file in ${DATABASES}; do
      log "Restoring database ${file}..."
      zcat ${DUMP_DIR}/data/${file}.sql.gz | mysql -u${MYSQL_USER} -p${MYSQL_PASS} -h${MYSQL_HOST} ${file}
    done
  done
}

# Main functionality
log "Starting restore."

# Check for lockfile
if [ -e ${LOCKFILE} ] ;then
  log "Lockfile ${LOCKFILE} exists, skipping backup."
  setAlertFlag 1
  exit 1
fi

# Write pid to lockfile
echo $$ > ${LOCKFILE}

downloadCloud
restore

# Get backup size and status
log "Cleaning up"

/bin/rm -rf ${DUMP_DIR}

# Remove lockfile
/bin/rm -f ${LOCKFILE}

# EMail report
#mail -s "Restore report for $(date)" $ALERT_EMAILS  < $LOGFILE

setAlertFlag 0

log "Restore ended."