#!/bin/bash

: ${DB_USER:="root"}
: ${DB_PASSWORD:="$MYSQL_ENV_MYSQL_ROOT_PASSWORD"}
: ${DB_HOST:="$MYSQL_PORT_3306_TCP_ADDR"}
: ${S3_URL:=$1}

if [[ -z $AWS_ACCESS_KEY_ID || -z $AWS_SECRET_ACCESS_KEY ]]
then
  echo "You must provide both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in environment"
  exit 1
fi

if [[ -z $DB_USER || -z $DB_PASSWORD || -z $DB_HOST ]]
then
  echo "You must either link to a mysql container or provide DB_USER, DB_PASSWORD, and DB_HOST"
  exit 1
fi

if [ -z $S3_URL ]
then
  echo "You must either pass an arugment or set S3_URL like s3://bucket/path/to/file.tgz"
  exit 1
fi

if [ -z $CHECK_URL ]
then
  CHECK_COMMAND="true"
else
  CHECK_COMMAND="curl $CHECK_URL"
fi

mysql_creds="-u$DB_USER -p$DB_PASSWORD -h$DB_HOST"

cd /tmp

while [ 1 ]
do
  databases=$(mysql $mysql_creds --skip-column-names -e "show databases")

  rm -r *.sql.gz

  for database in $databases
  do
    echo "Dumping $database"
    mysqldump $mysql_creds $database > $database.sql
    gzip $database.sql
  done

  aws s3 cp /tmp/ $S3_URL/ --exclude "*" --include "*.sql.gz" --recursive && $CHECK_COMMAND

  rm -r *.sql.gz

  if [ -z $BACKUP_INTERVAL ]
  then
    echo "Backup complete."
    exit 0
  else
    echo "Backup complete. Sleeping $BACKUP_INTERVAL until next backup"
    sleep $BACKUP_INTERVAL
  fi
done
