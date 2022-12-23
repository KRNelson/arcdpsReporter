FROM scottyhardy/docker-wine

RUN apt-get update && apt-get install -y --no-install-recommends \
    inotify-tools

# This link will redirect to the latest version. 
# https://github.com/baaron4/GW2-Elite-Insights-Parser/releases/latest

# This is an "example" link to download the zip for running the parser
# TODO: Use the link above to dynamically pull the latest build. 
# https://github.com/baaron4/GW2-Elite-Insights-Parser/releases/download/v2.46.1.2/GW2EI.zip
RUN wget https://github.com/baaron4/GW2-Elite-Insights-Parser/releases/download/v2.49.1.0/GW2EI.zip
RUN unzip GW2EI.zip

RUN mkdir /etc/reports
RUN chmod +777 /etc/reports

RUN mkdir /etc/logs
RUN chmod +777 /etc/logs
# ADD test.zevtc .

ADD report.conf .
ADD process.sh .
RUN chmod +777 process.sh

ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["./process.sh"]
