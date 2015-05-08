#!/bin/bash

: ${DB_USER:="root"}
: ${DB_PASSWORD:="$MYSQL_ENV_MYSQL_ROOT_PASSWORD"}
: ${DB_HOST:="$MYSQL_PORT_3306_TCP_ADDR"}
: ${S3_URL:=$1}

workdir=/tmp/mysql
output=/tmp/mysql.tgz

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

mysql_creds="-u$DB_USER -p$DB_PASSWORD -h$DB_HOST"

while [ 1 ]
do
  mkdir $workdir

  databases=$(mysql $mysql_creds --skip-column-names -e "show databases")

  for database in $databases
  do
    echo "Dumping $database"
    mysqldump $mysql_creds $database > $workdir/$database.sql
  done

  tar -czf $output $workdir

  aws s3 cp $output $S3_URL

  rm -rf $workdir
  rm -f $output

  if [ -z $BACKUP_INTERVAL ]
  then
    echo "Backup complete."
    exit 0
  else
    echo "Backup complete. Sleeping $BACKUP_INTERVAL until next backup"
    sleep $BACKUP_INTERVAL
  fi
done
