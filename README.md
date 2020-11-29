# MySQL backup-restore for docker-compose
## Overview

This a simple project based on Docker Compose to test backup and restore MySQL databases.

It is based on MySQL 5.7.X master-slave configuration and currently only uses mysqldump for backing up schema and data.
Backups are done locally and uploaded to S3 bucket.

## Usage

Set the AWS access/secret keys and S3 bucket name and region env variables in docker-compose-xxxx.yaml for db-tools container.

MySQL root access: root/root.
### Backup

```
docker-compose -f docker-compose-backup.yml -p backup up
```

Connect to db-tools container:
```
docker-compose -f docker-compose-backup.yml -p backup exec db-tools bash
```
Wait for the replication to start, it should show the following message in the slave-db_1 logs:
```
wait for MySQL init process done. Ready for start up
```
or check slave status from db-tools container
```
mysql -uroot -proot -hslave-db -e "show slave status\G"
```

Make a backup running the following command inside db-tools container:
```
/opt/scripts/backup.sh
```
Check logs in 
```
cat /opt/backup/backup-info.log
```

### Restore

```
docker-compose -f docker-compose-restore.yml -p restore up
```

Connect to db-tools container:
```
docker-compose -f docker-compose-restore.yml -p restore exec db-tools bash
```

Restore from the backup running the following command inside db-tools container:
```
/opt/scripts/restore.sh
```
Check logs in 
```
cat /opt/restore/restore-info.log
```


### Cleanup

To make a fresh start, clean the volumes and containers locally and files in S3 bucket.

```
docker-compose -f docker-compose-backup.yml -p backup down
docker rm -f backup_slave-db_1 backup_master-db_1
docker volume rm backup_db_master backup_db_slave backup_log_master backup_log_slave
```

```
docker-compose -f docker-compose-restore.yml -p restore down
docker rm -f restore_restore-db_1
docker volume rm restore_db_restore restore_log_restore
```