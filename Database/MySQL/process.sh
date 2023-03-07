#!/bin/bash

TARGET=$1
USER=$(cat $MYSQL_USER_FILE)
PASSWORD=$(cat $MYSQL_PASSWORD_FILE)
FILES=$(ls $TARGET/*.json)
PORT=33060

for FILENAME in $FILES; do
    echo $FILENAME
    mysqlsh --mysqlx --user=$USER --password=$PASSWORD --host=localhost --port=$PORT --schema=rpt --import $FILENAME IRPTJSON LOG_JSON_TE
    # ^ Modify this line to allow importing into 'unnamed' table. 
    # v Modify this sproc to read the 'unnamed' table. 
    # Execute mysql import sproc. 
done

rm -rf $TARGET

# Add a part here that pulls the IRPTJSON import table with the imported log tables. Existance check. Once complete, this will respond to UI