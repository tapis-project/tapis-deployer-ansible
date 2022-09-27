#!/bin/bash
# This program deletes all but the 2 most recent files in each of the backup directories. We can put this
# script on a cron to keep the backup directories small.


# this script can be described here: https://stackoverflow.com/questions/25785/delete-all-but-the-most-recent-x-files-in-bash

echo "cleaning up authenticator.."
cd /home/tapisdev/backups/authenticator && ls -tp | grep -v '/$' | tail -n +3 | xargs -I {} rm -- {}

echo "cleaning up pgrest..."
cd /home/tapisdev/backups/pgrest && ls -tp | grep -v '/$' | tail -n +3 | xargs -I {} rm -- {}

echo "cleaning up tenants..."
cd /home/tapisdev/backups/tenants && ls -tp | grep -v '/$' | tail -n +3 | xargs -I {} rm -- {}

echo "cleaning up systems..."
cd /home/tapisdev/backups/systems && ls -tp | grep -v '/$' | tail -n +3 | xargs -I {} rm -- {}

echo "cleaning up apps..."
cd /home/tapisdev/backups/apps && ls -tp | grep -v '/$' | tail -n +3 | xargs -I {} rm -- {}

echo "cleaning up jobs..."
cd /home/tapisdev/backups/jobs && ls -tp | grep -v '/$' | tail -n +3 | xargs -I {} rm -- {}

echo "cleaning up sk..."
cd /home/tapisdev/backups/sk && ls -tp | grep -v '/$' | tail -n +3 | xargs -I {} rm -- {}

echo "cleaning up streams..."
cd /home/tapisdev/backups/streams && ls -tp | grep -v '/$' | tail -n +7 | xargs -I {} rm -- {}
