#!/bin/bash
# This program deletes all but the 2 most recent files in each of the backup directories. We can put this
# script on a cron to keep the backup directories small.


# this script can be described here: https://stackoverflow.com/questions/25785/delete-all-but-the-most-recent-x-files-in-bash

#comment this to enable
exit 1

echo "cleaning up authenticator.."
cd {{ backups_data_dir }}/authenticator && ls -tp | grep -v '/$' | tail -n +3 | xargs -I {} rm -- {}

echo "cleaning up pgrest..."
cd {{ backups_data_dir }}/pgrest && ls -tp | grep -v '/$' | tail -n +3 | xargs -I {} rm -- {}

echo "cleaning up tenants..."
cd {{ backups_data_dir }}/tenants && ls -tp | grep -v '/$' | tail -n +3 | xargs -I {} rm -- {}

echo "cleaning up systems..."
cd {{ backups_data_dir }}/systems && ls -tp | grep -v '/$' | tail -n +3 | xargs -I {} rm -- {}

echo "cleaning up apps..."
cd {{ backups_data_dir }}/apps && ls -tp | grep -v '/$' | tail -n +3 | xargs -I {} rm -- {}

echo "cleaning up jobs..."
cd {{ backups_data_dir }}/jobs && ls -tp | grep -v '/$' | tail -n +3 | xargs -I {} rm -- {}

echo "cleaning up sk..."
cd {{ backups_data_dir }}/sk && ls -tp | grep -v '/$' | tail -n +3 | xargs -I {} rm -- {}

echo "cleaning up streams..."
cd {{ backups_data_dir }}/streams && ls -tp | grep -v '/$' | tail -n +7 | xargs -I {} rm -- {}
