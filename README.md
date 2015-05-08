# Docker mysql-backup container

A simple containerized script to backup each database in a given mysql
container and upload the resulting tarball to S3.

## Usage

### One shot backup

Backup a running MySQL container called `some-mysql` to the specified S3
path.

```

docker run \
  -e AWS_ACCESS_KEY_ID=awskey \
  -e AWS_SECRET_ACCESS_KEY=secret \
  --rm --link some-mysql:mysql \
  watermarkchurch/mysql-backup
  s3://awsbucket/path/to/archive.tgz

```

### Daemonized backup

This will upload a new archive to the same S3 path each time the script
runs. I recommend turning on Versioning on the target bucket and setting
up a rule to delete or archive versions after some interval of time.

```

docker run \
  -e AWS_ACCESS_KEY_ID=awskey \
  -e AWS_SECRET_ACCESS_KEY=secret \
  -e BACKUP_INTERVAL=86400 \
  --name=mysql-backup \
  -d --link some-mysql:mysql \
  watermarkchurch/mysql-backup
  s3://awsbucket/path/to/archive.tgz

```

### Managed with Systemd unit

```
[Unit]
Description=MySQL Backup Container
After=docker.service

[Service]
TimeoutStartSec=0
Restart=on-failure
ExecStartPre=-/usr/bin/docker kill mysql-backup
ExecStartPre=-/usr/bin/docker rm mysql-backup
ExecStartPre=-/usr/bin/docker pull watermarkchurch/mysql-backup
ExecStart=/usr/bin/docker run \
  -e AWS_ACCESS_KEY_ID=access_id \
  -e AWS_SECRET_ACCESS_KEY=secret_key \
  -e BACKUP_INTERVAL=86400 \
  --link mysql:mysql \
  --name=mysql-backup \
  watermarkchurch/mysql-backup \
  s3://bucketname/backups/mysql.tgz
ExecStop=/usr/bin/docker stop mysql-backup

[Install]
WantedBy=multi-user.target
```
