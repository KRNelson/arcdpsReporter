# Given a log file, parses that log file using both the Simple and Elite parsers.
# Generates a json representation of the log file parsed, to be passed into a database for processing. 
$LogFile = $args[0]
$LogHash = Get-FileHash $LogFile

$SimpleParserJSON = & '.\Simple Parser\SimpleParser.exe' json $LogFile | ConvertFrom-JSON
& '.\Elite Insights Parsers\Executable\GuildWars2EliteInsights.exe' -c '.\report.conf' -p $LogFile | Out-Null

# Log file can be used for error checking the Elite Parser output. 
$EliteParserLOG = Move-Item -Path '.\Elite Insights Parsers\reports\*.log' -Destination '.\Elite Insights Parsers\reports\log' -Force -PassThru

# HTML file is used by the web app for displaying individual pulls. 
$EliteParserHTML = Move-Item -Path '.\Elite Insights Parsers\reports\*.html' -Destination '.\Elite Insights Parsers\reports\html' -Force -PassThru

# JSON file is uploaded to the database. 
$EliteParserJSON = Move-Item -Path '.\Elite Insights Parsers\reports\*.json' -Destination '.\Elite Insights Parsers\reports\json' -Force -PassThru | Get-Content -Raw | ConvertFrom-JSON
Copy-Item -Path $LogFile -Destination '.\Elite Insights Parsers\reports\evtc' -Force

# Final result of what will be sent to the database. 
$ResultJSON = '{parsers: {simple: null, elite: null}, file: {name: null, hash: null, log: null, html: null}}' | ConvertFrom-JSON
$ResultJSON.parsers.simple = $SimpleParserJSON
$ResultJSON.parsers.elite = $EliteParserJSON

$ResultJSON.file.name = (Get-Item $LogFile).Name
$ResultJSON.file.hash = $LogHash.hash
$ResultJSON.file.log = $EliteParserLOG.name
$ResultJSON.file.html = $EliteParserHTML.name

# ConvertTo-JSON -Depth 100 -Compress $ResultJSON | Out-File "result.json"
ConvertTo-JSON -Depth 100 -Compress $ResultJSON | node ..\Web\Node\parse.js