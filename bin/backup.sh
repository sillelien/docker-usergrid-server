#!/bin/bash -eu
/app/cassandra/bin/nodetool -h ${CASS_HOST} -p 7199 snapshot UserGrid
tar -cz /app/cassandra/  |  openssl enc -aes-256-cbc -k $(/root/backup.pwd.txt) -e > /app/downloads/backup.tar.gz.enc
/sbin/setuser app chown app:app /app/downloads/backup.tar.gz.enc
/app/cassandra/bin/nodetool -h ${CASS_HOST} -p 7199 clearsnapshot

