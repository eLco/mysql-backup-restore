#!/bin/bash

set -e

LOGFILE="/opt/backup/backup-info.log"
ERROFILE="/opt/backup/backup-error.log"
LOCKFILE="/opt/backup/backup.lock"
BACKUP_DIR="/opt/backup/"
DUMP_DIR="/opt/backup/dump"
BINARY_DIR="/opt/backup/binary"
STATUSFILE="/opt/backup/backup-status"
MYSQL_USER=root
MYSQL_PASS=root
MYSQL_HOST=slave-db
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

function sqlDump () {
        log "Creating full mysqldump backup in ${DUMP_DIR}"

        if [ -d "${DUMP_DIR}" ]; then
                /bin/rm -rf ${DUMP_DIR}
        fi
        
        mkdir -p ${DUMP_DIR}

        for db in ${DATABASES}; do
                if [ "${db}" != "information_schema" ] || [ "${db}" != "sys" ] || [ "${db}" != "performance_schema" ] || [ "${db}" != "mysql" ]; then
                        log "Dumping database '${db}'...";
                        mysqldump -u${MYSQL_USER} -p${MYSQL_PASS} -h${MYSQL_HOST} --single-transaction ${db} | gzip > ${DUMP_DIR}/${db}.sql.gz
                        log "Done."

                        log "Dumping database schema '${db}'...";
                        mysqldump -u${MYSQL_USER} -p${MYSQL_PASS} -h${MYSQL_HOST} --single-transaction --no-data ${db} | gzip > ${DUMP_DIR}/${db}.frm.sql.gz
                        log "Done."
                fi
        done

        
}

function uploadCloud () {
        log "Uploading backups to ${S3_BUCKET}"
        for file in ${DATABASES}; do
                log "Uploading ${file} schema..."
	        aws s3 cp ${DUMP_DIR}/${file}.frm.sql.gz s3://$S3_BUCKET/schemas/${TS}/${file}.frm.sql.gz
                log "Done."

                log "Uploading ${file} dump..."
	        aws s3 cp ${DUMP_DIR}/${file}.sql.gz s3://$S3_BUCKET/data/${TS}/${file}.sql.gz
                log "Done."
        done
}

# Main functionality
log "Starting backup."

# Check for lockfile
if [ -e ${LOCKFILE} ] ;then
  log "Lockfile ${LOCKFILE} exists, skipping backup."
  setAlertFlag 1
  exit 1
fi

# Write pid to lockfile
echo $$ > ${LOCKFILE}

#log "Starting binary backup"

#binaryBackup
#uploadCloud

log "Starting logical backup"

sqlDump
uploadCloud


# Get backup size and status
log "Cleaning up"
#log "Binary backup size: `du -sh ${BINARY_DIR}`"
log "Logical backup size: `du -sh ${DUMP_DIR}`"

/bin/rm -rf ${DUMP_DIR}

# Remove lockfile
/bin/rm -f ${LOCKFILE}

# EMail report
#mail -s "Backup report for $(date)" $ALERT_EMAILS  < $LOGFILE

setAlertFlag 0

log "Backup ended."
