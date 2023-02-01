#!/bin/bash

TARGET=/etc/logs

wine msiexec /i wine-mono-7.4.0-x86.msi

inotifywait -m -e create -e moved_to --format "%f" $TARGET \
        | while read FILENAME
                do
                    wine /GuildWars2EliteInsights.exe -p -c /report.conf $TARGET/$FILENAME
                done