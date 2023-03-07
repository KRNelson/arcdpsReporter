#!/bin/bash

# Script to process all logs that have not yet been processed. 
# Assume that any all log files in any folder need processing. 
#   Simply list the folders in /etc/logs and call process.sh on each one...

FOLDERS=$(ls /etc/logs)

for FOLDER in $FOLDERS; do
    echo $FOLDER
    ./process.sh $FOLDER
done