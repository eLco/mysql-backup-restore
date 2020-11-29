#!/bin/bash

cd /docker-entrypoint-initdb.d/test_db \
  && mysql -uroot -proot < employees.sql