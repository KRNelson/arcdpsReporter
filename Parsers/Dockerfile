FROM scottyhardy/docker-wine

# This link will redirect to the latest version. 
# https://github.com/baaron4/GW2-Elite-Insights-Parser/releases/latest

# This is an "example" link to download the zip for running the parser
# TODO: Use the link above to dynamically pull the latest build. 
# https://github.com/baaron4/GW2-Elite-Insights-Parser/releases/download/v2.46.1.2/GW2EI.zip

RUN wget https://github.com/baaron4/GW2-Elite-Insights-Parser/releases/download/v2.46.1.2/GW2EI.zip
RUN unzip GW2EI.zip

RUN mkdir reports
RUN chmod +777 reports

ADD report.conf report.conf
ADD test.zevtc test.zevtc

ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["wine", "GuildWars2EliteInsights.exe", "-p", "-c", "report.conf", "test.zevtc"]