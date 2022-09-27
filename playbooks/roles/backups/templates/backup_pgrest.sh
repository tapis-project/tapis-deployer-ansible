#!/bin/bash
# This program creates a .sql backup of the Tenants API Postgres DB by exec'ing into the running Postgres 
# container and issuing pg_dump. It gzips and copies the file down to local disk and then to an s3-compatible
# storage bucket.
# NOTE: the s3 bucket must already exist or else this program will error.
#       you can create a bucket with the command:  s3cmd mb s3://<bucket-name>
#       you can list contents of existing buckets with the command: s3cmd ls s3://<bucket-name>


export d=`date +%Y%m%d`
export SERVICE=pgrest # TODO
export ENV=dev # TODO
export backupfile="{{ backups_data_dir }}/$SERVICE/${ENV}-${SERVICE}-backup-${d}.sql"

export POSTGRES_USER=pgrest # TODO
export POSTGRES_PASSWORD=`kubectl get secret tapis-pgrest-secrets -o json | jq -r '.data["kubernetes-postgres"]' | base64 -d` # TODO 

export POSTGRES_DEPLOYMENT=deploy/pgrest-postgres #TODO 
# note -- add the "pgrestdb" at the end of the PG_URL since it differs from the user.
export PG_URL="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost:5432/pgrestdb"


if [ ! -f ${backupfile}.gz ]
  then
 
    kubectl exec -it $POSTGRES_DEPLOYMENT -- /bin/bash -c "pg_dump --dbname=$PG_URL" > ${backupfile} && \
    gzip ${backupfile} && \
    s3cmd put ${backupfile}.gz s3://tapis-${ENV}-backups && \
# remove from local disk in separate script
#    rm -f ${backupfile}.gz && \
    echo "pgrest-dev backup success" | mail -s "pgrest-dev backup success" backups@example.com
  else
    echo "pgrest-dev backup failed" | mail -s "pgrest-dev backup failed" backups@example.com
  fi

