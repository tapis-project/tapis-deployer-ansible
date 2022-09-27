#!/bin/bash
#
# Program to restore databases from backups for the Streams service.
# Timestamp of backup must be provided in the format YYYYMMDD
#
PRG_NAME=$(basename "$0")
USAGE1="Usage: $PRG_NAME <YYYYMMDD>"
USAGE2="E.g. : $PRG_NAME 20210420"
if [ $# -ne 1 ]; then
  echo "$USAGE1"
  echo "$USAGE2"
  exit 1
fi

# --------------------
# INPUTS/CONFIGURATION
# ---------------------
export backuptimestamp=$1
export SERVICE=streams
export ENV=dev
export bucketname=tapis-${ENV}-backups
export tmpdir=/tmp/${bucketname}
export backupname=${ENV}-${SERVICE}-backup-${backuptimestamp}.sql.gz


#get pod names
INFLUXDB=`kubectl get pods| grep '^chords-influxdb*'|awk '{print $1}'`
#KAPACITOR=`kubectl get pods| grep '^kapacitor*'|awk '{print $1}'`
MYSQL=`kubectl get pods| grep '^chords-mysql*'|awk '{print $1}'`

export backupdate=$1
export influx_backup=${ENV}-${SERVICE}-influx_backup-${backupdate}
#export kapacitor_file=${ENV}-${SERVICE}-kap_backup-${backupdate}.db
export mysql_file=${ENV}-${SERVICE}-mysql_backup-${backupdate}.sql



# ------
# LOGIC
# ------
set -xv
# create a temporary directory for working and move to it
mkdir -p ${tmpdir}
cd ${tmpdir}


#restore InfluxDB
# download the backup file from s3.
s3cmd get s3://${bucketname}/${influx_backup}.tar.gz
# unpack the file
gzip -d ${influx_backup}.tar.gz
tar -xvf ${influx_backup}.tar
kubectl cp ${influx_backup} ${INFLUXDB}:/tmp/influx_backup
kubectl exec ${INFLUXDB} -- bash -c "influx restore /tmp/influx_backup"
kubectl exec ${INFLUXDB} -- bash -c "rm -rf /tmp/influx_backup"

#restore Kapacitor replace /var/lib/kapacitor/kapacitor.db
# download the backup file from s3.
#s3cmd get s3://${bucketname}/${kapacitor_file}.gz

# unpack the file
#gzip -d ${kapacitor_file}.gz
#kubectl cp ${kapacitor_file} ${KAPACITOR}:/tmp/kap_backup.db
#kubectl exec ${KAPACITOR} -- bash -c "mv /tmp/kap_backup.db /var/lib/kapacitor/kapacitor.db"
#kubectl exec ${KAPACITOR} -- bash -c "rm /tmp/kap_backup.db"

#restore Mysql
# download the backup file from s3.
s3cmd get s3://${bucketname}/${mysql_file}.gz

# unpack the file
gzip -d ${mysql_file}.gz
kubectl cp ${mysql_file} ${MYSQL}:/tmp/chords_mysql_backup.sql
kubectl exec ${MYSQL} -- bash -c "mysql < /tmp/chords_mysql_backup.sql"
kubectl exec ${MYSQL} -- bash -c "rm  /tmp/chords_mysql_backup.sql"
