#!/bin/bash

# create user for replication
mysql -uroot -proot -e "GRANT \
    REPLICATION SLAVE, \
    REPLICATION CLIENT \
    ON *.* \
    TO 'replication'@'%' \
    IDENTIFIED BY 'replication'; \
    FLUSH PRIVILEGES;"
