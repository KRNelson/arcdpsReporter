FROM mysql:8-debian

ENV MYSQL_ALLOW_EMPTY_PASSWORD=1

ADD ./CREATE/SCHEMAS.sql ./docker-entrypoint-initdb.d/_01_SCHEMAS.sql
ADD ./CREATE/TABLES.sql ./docker-entrypoint-initdb.d/_02_TABLES.sql
ADD ./CREATE/PROCEDURES.sql ./docker-entrypoint-initdb.d/_03_PROCEDURES.sql
ADD ./CREATE/USERS.sql ./docker-entrypoint-initdb.d/_04_USERS.sql

RUN apt-get update
RUN apt-get install -y --no-install-recommends libcurl4 libssh-4

ADD mysql-shell_8.0.32-1debian11_amd64.deb .

# ADD mysql-apt-config_0.8.24-1_all.deb .
# RUN dpkg -i mysql-apt-config_0.8.24-1_all.deb

RUN dpkg -i mysql-shell_8.0.32-1debian11_amd64.deb

RUN apt-get update
RUN apt-get install mysql-shell -y --no-install-recommends

# RUN rm mysql-apt-config_0.8.24-1_all.deb
RUN rm mysql-shell_8.0.32-1debian11_amd64.deb
RUN apt-get remove -y lsb-release wget gnupg curl

ADD process.sh .
RUN sed -i 's/\r$//' process.sh
RUN chmod +777 process.sh

ADD reprocess.sh .
RUN sed -i 's/\r$//' reprocess.sh
RUN chmod +777 reprocess.sh


EXPOSE 3306 33060