FROM scottyhardy/docker-wine

RUN apt-get update && apt-get install -y --no-install-recommends unzip

# ADD wine-mono-7.4.0-x86.msi .
# RUN chmod +777 wine-mono-7.4.0-x86.msi
# RUN wine msiexec /i wine-mono-7.4.0-x86.msi

# This link will redirect to the latest version. 
# https://github.com/baaron4/GW2-Elite-Insights-Parser/releases/latest

# This is an "example" link to download the zip for running the parser
# TODO: Use the link above to dynamically pull the latest build. 
# https://github.com/baaron4/GW2-Elite-Insights-Parser/releases/download/v2.46.1.2/GW2EI.zip
# RUN wget https://github.com/baaron4/GW2-Elite-Insights-Parser/releases/download/v2.50.1.0/GW2EI.zip
ADD GW2EI.zip .
RUN unzip GW2EI.zip

ADD report.conf .
ENTRYPOINT ["/usr/bin/entrypoint"]