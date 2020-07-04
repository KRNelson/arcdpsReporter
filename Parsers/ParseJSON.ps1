# Given a log file, parses that log file using both the Simple and Elite parsers.
# Generates a json representation of the log file parsed, to be passed into a database for processing. 
$LogFile = '.\20200703-185049.evtc'

$SimpleParserJSON = & '.\Simple Parser\SimpleParser.exe' json $LogFile | ConvertFrom-JSON
& '.\Elite Insights Parsers\Executable\GuildWars2EliteInsights.exe' -c '.\report.conf' -p $LogFile | Out-Null

Move-Item -Path '.\Elite Insights Parsers\reports\*.log' -Destination '.\Elite Insights Parsers\reports\log'
Move-Item -Path '.\Elite Insights Parsers\reports\*.html' -Destination '.\Elite Insights Parsers\reports\html'
$EliteParserJSON = Move-Item -Path '.\Elite Insights Parsers\reports\*.json' -Destination '.\Elite Insights Parsers\reports\json' -PassThru | Get-Content -Raw | ConvertFrom-JSON
Copy-Item -Path $LogFile -Destination '.\Elite Insights Parsers\reports\evtc'

$ResultJSON = '{parsers: {simple: null, elite: null}}' | ConvertFrom-JSON
$ResultJSON.parsers.simple = $SimpleParserJSON
$ResultJSON.parsers.elite = $EliteParserJSON

ConvertTo-JSON -Depth 100 -Compress $ResultJSON | Out-File "result.json"