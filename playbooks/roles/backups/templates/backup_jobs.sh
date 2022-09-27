#!/bin/bash
# This program creates a .sql backup of the Jobs API Postgres DB by exec'ing into the running Postgres 
# container and issuing pg_dump. It gzips and copies the file down to local disk and then to an s3-compatible
# storage bucket.
# NOTE: the s3 bucket must already exist or else this program will error.
#       you can create a bucket with the command:  s3cmd mb s3://<bucket-name>
#       you can list contents of existing buckets with the command: s3cmd ls s3://<bucket-name>

echo "Setting up env variable ..."
export SERVICE=jobs
export ENV=dev

echo "Setting up backup dir and file names ..." 
export bucketname=tapis-${ENV}-backups

export backuptimestamp=`date +%Y%m%d`
export backupname=${ENV}-${SERVICE}-backup-${backuptimestamp}.sql
export backupdir="/home/tapis${ENV}/backups/${SERVICE}"
export backupfile="${backupdir}/${backupname}"

echo "Get postgres username, password and connection string ..."
export POSTGRES_USER=postgres
# From the dicumentation: https://www.postgresql.org/docs/12/app-pg-dumpall.html:
# Since pg_dumpall needs to connect many databases, the database name in the connection string will be ignored.
# POSTGRES_DBNAME can be postgres or tapisjobsdb
# We are using the postgres database where all global objects will be dumped. This is also the default option when no database is specified.
export POSTGRES_DBNAME=postgres
export POSTGRES_PASSWORD=`kubectl get secret tapis-${SERVICE}-secrets -o json | jq -r '.data["postgres-password"]' | base64 -d`

export POSTGRES_DEPLOYMENT=deploy/${SERVICE}-postgres
export PG_URL="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost:5432/$POSTGRES_DBNAME"

# Check results of config
if [ -z ${POSTGRES_PASSWORD} ]; then
  echo "Cannot determine tapis postgres password"
  exit 1
fi

echo "Create backup dir ..."
mkdir -p ${backupdir}

if [ ! -f ${backupfile}.gz ]; then
  echo "pg_dumpall databases ..."
  kubectl exec -it $POSTGRES_DEPLOYMENT -- /bin/bash -c "pg_dumpall --clean --dbname=$PG_URL" > ${backupfile} && \
  echo "compressing into a zip file after the dump ..."
  gzip ${backupfile} && \
  echo "upload the zipped file to s3 bucket for backups"
  s3cmd put ${backupfile}.gz s3://${bucketname} && \
  echo "${SERVICE}-${ENV} backup success" | mail -s "${SERVICE}-${ENV} backup success" backups@example.com
else
  echo "${SERVICE}-${ENV} backup failed" | mail -s "${SERVICE}-${ENV} backup failed" backups@example.com
fi
