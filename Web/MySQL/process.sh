#!/bin/bash

TARGET=/etc/reports
USER=$(cat $MYSQL_USER_FILE)
PASSWORD=$(cat $MYSQL_PASSWORD_FILE)

inotifywait -m -e close_write --format "%f" $TARGET \
        | while read FILENAME
                do
                    if [[ "$FILENAME" == *.json ]]
                    then
                        # Maybe... Instead of having a target, just let mysqlsh --import create the target table.
                        # Then, in another call immediately after, run the import into relational tables. 
                        # Make sure to import the filename as well as part of the import into relational tables. 
                        mysqlsh --mysqlx --user=$USER --password=$PASSWORD --host=backend --port=33060 --schema=rpt --import $TARGET/$FILENAME IRPTJSON LOG_JSON_TE
                        # rm $TARGET/$FILENAME

                        # On NodeJS side, after moving the files. 
                        # Start polling for the existance of all the filenames in mysql. 
                        #   It'll be a partial name...
                    fi
                done