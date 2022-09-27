#!/bin/bash
# This program creates a .sql backup of the Tenants API Postgres DB by exec'ing into the running Postgres 
# container and issuing pg_dump. It gzips and copies the file down to local disk and then to an s3-compatible
# storage bucket.
# NOTE: the s3 bucket must already exist or else this program will error.
#       you can create a bucket with the command:  s3cmd mb s3://<bucket-name>
#       you can list contents of existing buckets with the command: s3cmd ls s3://<bucket-name>


export d=`date +%Y%m%d`
export SERVICE=authenticator # TODO
export ENV=dev # TODO
export backupfile="/home/tapisdev/backups/$SERVICE/${ENV}-${SERVICE}-backup-${d}.sql"

export POSTGRES_USER=authenticator # TODO
export POSTGRES_PASSWORD=`kubectl get secret tapis-authenticator-secrets -o json | jq -r '.data["postgres-password"]' | base64 -d` # TODO 

export POSTGRES_DEPLOYMENT=deploy/authenticator-postgres #TODO 
export PG_URL="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost:5432"


if [ ! -f ${backupfile}.gz ]
  then
 
    kubectl exec -it $POSTGRES_DEPLOYMENT -- /bin/bash -c "pg_dump --dbname=$PG_URL" > ${backupfile} && \
    gzip ${backupfile} && \
    s3cmd put ${backupfile}.gz s3://tapis-${ENV}-backups && \
# remove from local disk in separate script
#    rm -f ${backupfile}.gz && \
    echo "authenticator-dev backup success" | mail -s "authenticator-dev backup success" backups@example.com
  else
    echo "authenticator-dev backup failed" | mail -s "authenticator-dev backup failed" backups@example.com
  fi

