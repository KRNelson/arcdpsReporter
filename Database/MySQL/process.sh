#!/bin/bash

TARGET=/etc/reports

inotifywait -m -e create -e moved_to --format "%f" $TARGET \
        | while read FILENAME
                do
                    echo $FILENAME
                done