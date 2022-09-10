#!/bin/bash

TARGET=/etc/logs

inotifywait -m -e create -e moved_to --format "%f" $TARGET \
        | while read FILENAME
                do
                    wine /GuildWars2EliteInsights.exe -p -c /report.conf $TARGET/$FILENAME
                done