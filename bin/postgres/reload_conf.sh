#!/bin/bash
if [ $# -lt 1 ] ; then
    echo "Usage: $0 <ip>"
    exit 1
fi
source /opt/cpm/bin/common_lib.sh
enable_debugging

source /opt/cpm/bin/setenv.sh

cp ${PGDATA}/postgresql.conf /tmp/postgresql.conf
sed -r -i  "s/host=([0-9]{1,3}\.){3}[0-9]{1,3}/host=$1/" ${PGDATA}/postgresql.conf
pg_ctl reload
