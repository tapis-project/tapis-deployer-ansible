#!/bin/bash
# This program creates a .sql backup of the Applications API Postgres DB by exec'ing into the running Postgres 
# container and issuing pg_dump. It gzips and copies the file down to local disk and then to an s3-compatible
# storage bucket.
# NOTE: the s3 bucket must already exist or else this program will error.
#       you can create a bucket with the command:  s3cmd mb s3://<bucket-name>
#       you can list contents of existing buckets with the command: s3cmd ls s3://<bucket-name>

export SERVICE=apps
export ENV=dev

export bucketname=tapis-${ENV}-backups

export backuptimestamp=`date +%Y%m%d`
export backupname=${ENV}-${SERVICE}-backup-${backuptimestamp}.sql
export backupdir="/home/tapis${ENV}/backups/${SERVICE}"
export backupfile="${backupdir}/${backupname}"

export POSTGRES_USER=tapis_app
export POSTGRES_DBNAME=tapisappdb
export POSTGRES_PASSWORD=`kubectl get secret tapis-${SERVICE}-secrets -o json | jq -r '.data["postgres-password"]' | base64 -d`

export POSTGRES_DEPLOYMENT=deploy/${SERVICE}-postgres
export PG_URL="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost:5432/$POSTGRES_DBNAME"

# Check results of config
if [ -z ${POSTGRES_PASSWORD} ]; then
  echo "Cannot determine postgres password"
  exit 1
fi

mkdir -p ${backupdir}

if [ ! -f ${backupfile}.gz ]; then
  kubectl exec -it $POSTGRES_DEPLOYMENT -- /bin/bash -c "pg_dump --dbname=$PG_URL" > ${backupfile} && \
  gzip ${backupfile} && \
  s3cmd put ${backupfile}.gz s3://${bucketname} && \
  echo "${SERVICE}-${ENV} backup success" | mail -s "${SERVICE}-${ENV} backup success" backups@example.com
else
  echo "${SERVICE}-${ENV} backup failed" | mail -s "${SERVICE}-${ENV} backup failed" backups@example.com
fi
