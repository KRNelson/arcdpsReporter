FROM mysql

ENV MYSQL_ALLOW_EMPTY_PASSWORD=1

ADD ./CREATE/SCHEMAS.sql ./docker-entrypoint-initdb.d/_01_SCHEMAS.sql
ADD ./CREATE/TABLES.sql ./docker-entrypoint-initdb.d/_02_TABLES.sql
ADD ./CREATE/PROCEDURES.sql ./docker-entrypoint-initdb.d/_03_PROCEDURES.sql

EXPOSE 3306