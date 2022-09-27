#!/bin/bash
#
# Program to restore a database from a backup for the Systems service.
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

export SERVICE=systems
export ENV=dev

export bucketname=tapis-${ENV}-backups
export tmpdir=/tmp/${bucketname}

export backupname=${ENV}-${SERVICE}-backup-${backuptimestamp}.sql.gz

export POSTGRES_USER=tapis_sys
export POSTGRES_DBNAME=tapissysdb

export POSTGRES_DEPLOYMENT=deploy/${SERVICE}-postgres


# Determine one pod name for the service
export POSTGRES_POD=`kubectl get pod | grep ${SERVICE}-postgres | awk '{printf "%s\n", $1}' | head -n 1`
if [ -z ${POSTGRES_POD} ]; then
  echo "Cannot determine postgres POD name"
  exit 1
fi

# ------
# LOGIC
# ------
set -xv
# create a temporary directory for working and move to it
mkdir -p ${tmpdir}
cd ${tmpdir}

# download the backup file from s3.
s3cmd get s3://${bucketname}/${backupname}

# unpack the file
gzip -d $backupname

# Set the name for the the unpacked file 
export backupsql=${backupname%.gz}
echo "Restoring ${backupsql} ..."

# copy the sql file to the postgres pod
kubectl cp $backupsql $POSTGRES_POD:/$backupsql

kubectl exec -it $POSTGRES_POD -- /bin/bash -c "psql -h localhost -p 5432 -d ${POSTGRES_DBNAME} -U ${POSTGRES_USER} < $backupsql"
