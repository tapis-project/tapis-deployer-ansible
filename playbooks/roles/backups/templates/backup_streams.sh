#!/bin/bash
export SERVICE=streams
export ENV=dev
export bucketname=tapis-${ENV}-backups
export backupdate=`date +%Y%m%d`
export backupdir="{{ backups_data_dir }}/${SERVICE}"

export influx_dir=${backupdir}/${ENV}-${SERVICE}-influx_backup-${backupdate}
#export kapacitor_file=${backupdir}/${ENV}-${SERVICE}-kap_backup-${backupdate}.db
export mysql_file=${backupdir}/${ENV}-${SERVICE}-mysql_backup-${backupdate}.sql
#get pod names
export INFLUXDB=`kubectl get pods| grep '^chords-influxdb*'|awk '{print $1}'`
#export KAPACITOR=`kubectl get pods| grep '^kapacitor*'|awk '{print $1}'`
export MYSQL=`kubectl get pods| grep '^chords-mysql*'|awk '{print $1}'`

echo "Create backup dir ..."
mkdir -p ${backupdir}

#backup InfluxDB
echo "creating influxdb backup"
kubectl exec ${INFLUXDB} -- bash -c "influx backup /tmp/influx_backup"
echo "copy influx backup directory to host at ${influx_dir}"
kubectl cp ${INFLUXDB}:tmp/influx_backup ${influx_dir}
echo "removing influx backup from container"
kubectl exec ${INFLUXDB} -- bash -c "rm -rf /tmp/influx_backup}"
#backup Kapacitor
#echo "creating kapacitor backup"
#kubectl exec ${KAPACITOR} -- bash -c "curl http://admin:chords_ec_demo@localhost:9092/kapacitor/v1/storage/backup > /tmp/kap_backup.db"
##echo "copy kapacitor backup file to host at ${kapacitor_file}"
#kubectl cp ${KAPACITOR}:tmp/kap_backup.db ${kapacitor_file}
#echo "removing kapacitor backup from container"
#kubectl exec ${KAPACITOR}  -- bash -c "rm  /tmp/kap_backup.db"
#backup Mysql
echo "creating chords mysql backup"
kubectl exec ${MYSQL}  -- bash -c "mysqldump --all-databases > /tmp/chords_mysql_backup.sql"
echo "copying chords mysql backup to host at ${mysql_file}"
kubectl cp ${MYSQL}:tmp/chords_mysql_backup.sql ${mysql_file}
echo "removing chords mysql backup from container"
kubectl exec ${MYSQL}  -- bash -c "rm  /tmp/chords_mysql_backup.sql"

if [[ -d ${influx_dir} ]] && [[ -f ${mysql_file} ]]
then
  echo "compressing into a zip files..."
  tar -cvf ${influx_dir}.tar --remove-files ${influx_dir}
  gzip ${influx_dir}.tar ${mysql_file}
  echo "upload the zipped file to s3 bucket for backups"
  #s3cmd put ${kapacitor_file}.gz s3://${bucketname}
  s3cmd put ${mysql_file}.gz s3://${bucketname}
  s3cmd put ${influx_dir}.tar.gz s3://${bucketname}
  echo "${SERVICE}-${ENV} backup success" | mail -s "${SERVICE}-${ENV} backup success" backups@example.com
else
  echo "${SERVICE}-${ENV} backup failed" | mail -s "${SERVICE}-${ENV} backup failed" backups@example.com
fi
