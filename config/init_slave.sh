#!/bin/bash

until mysql -hmaster-db -uroot -proot -e "select 1 from dual" | grep -q 1;
do
    >&2 echo "Replication master is unavailable - sleeping"
    sleep 1
done
>&2 echo "Replication master is running"

mysql -uroot -proot -e "RESET MASTER; \
    CHANGE MASTER TO \
    MASTER_HOST='master-db', \
    MASTER_PORT=3306, \
    MASTER_USER='replication', \
    MASTER_PASSWORD='replication';"

mysqldump \
    --host=master-db \
    --port=3306 \
    --user=root \
    --password=root \
    --protocol=tcp \
    --master-data=1 \
    --add-drop-database \
    --flush-logs \
    --flush-privileges \
    --all-databases \
    | mysql -uroot -proot


mysql -uroot -proot -e "START SLAVE;"