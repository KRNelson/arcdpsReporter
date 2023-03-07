#!/bin/bash

# TARGET=/etc/reports/
# wine msiexec /i wine-mono-7.4.0-x86.msi
# wine /GuildWars2EliteInsights.exe -p -c /report.conf $TARGET/$FILENAME

sed -i `s/UPLOAD_FOLDER/$1/` report.conf 
