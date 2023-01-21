FROM debian:bullseye-slim

RUN apt-get update
RUN apt-get install -y --no-install-recommends lsb-release wget gnupg

ADD mysql-apt-config_0.8.24-1_all.deb .
RUN dpkg -i mysql-apt-config_0.8.24-1_all.deb

RUN apt-get update
RUN apt-get install mysql-shell -y --no-install-recommends

RUN rm mysql-apt-config_0.8.24-1_all.deb

RUN apt-get install -y --no-install-recommends inotify-tools

RUN mkdir /etc/reports
RUN chmod +777 /etc/reports

RUN mkdir /etc/reports/finished
RUN chmod +777 /etc/reports/finished

ADD process.sh .
RUN sed -i 's/\r$//' process.sh
RUN chmod +777 process.sh

CMD ["/bin/bash", "process.sh"]
