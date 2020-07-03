# arcdpsReporter
Collection of components used for reporting a series of dpsReport results. 
Users are capable of upload logs into a database and viewing the results of a series of uploaded logs. 

# Components
## Parsers
### Elite Insights Parser
This parser is used by dpsreport and is considered a reliable source of metrics. 
https://github.com/baaron4/GW2-Elite-Insights-Parser/
### Simple Parser
This parser is open source C++ and relatively easy to compile. It reads the header information in the log file and has the capability of outputing results as JSON. 
https://github.com/jacob-keller/L0G-101086/tree/master/simpleArcParse
## Database
### MySQL
"The world's most popular open source database" - Their Website
MySQL is chosen due to it's popularity and it's prevelence as a free database option on various hosting options. 
Another DBMS may be used, as long as it remains compatible with the other components. 
https://www.mysql.com/ 
## Web
### Apache
"The Apache HTTP Server ("httpd") was launched in 1995 and it has been the most popular web server on the Internet since April 1996. It has celebrated its 25th birthday as a project in February 2020." - Their Website
Apache is chosen due to popularity and ease of use. 
Another Web Server option may be used, as long as it remains compatible with the other components. 
https://httpd.apache.org/ 
### Vue.js
"The Progressive JavaScript Framework" - Their Website
https://vuejs.org/ 