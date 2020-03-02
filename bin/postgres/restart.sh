#!/bin/bash
source /opt/cpm/bin/common_lib.sh
enable_debugging

source /opt/cpm/bin/setenv.sh

if [ $# -eq 0 ];
then
    echo_err "params lost"
    exit 1
fi

export PG_PRIMARY_HOST=$1
export PG_PRIMARY_PORT=${PG_PRIMARY_PORT:-$2}
export PG_PRIMARY_USER=$PG_PRIMARY_USER

function initialize_replica_conf() {
    cp $PGDATA/postgresql.conf $PGDATA/postgresql.conf.bak
    sed -i '/primary_conninfo/d' $PGDATA/postgresql.conf	
    echo_info "Setting up recovery using methodology for PostgreSQL 12 and above."
    # the primary_conninfo string stays mostly the same
    PGCONF_PRIMARY_CONNINFO="application_name=${APPLICATION_NAME} host=${PG_PRIMARY_HOST} port=${PG_PRIMARY_PORT} user=${PG_PRIMARY_USER}"
    echo "primary_conninfo = '${PGCONF_PRIMARY_CONNINFO}'" >> $PGDATA/postgresql.conf
    # and put the server into standby mode
    touch $PGDATA/standby.signal
}


initialize_replica_conf

pg_ctl restart -m fast -w -t 120 -D $PGDATA