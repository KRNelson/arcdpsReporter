FROM httpd:bullseye

# RUN apt-get install npm
RUN apt-get update
RUN apt-get install -y npm --no-install-recommends

RUN npm install -g elm@0.19.1
RUN npm install -g uglify-js

COPY . /usr/local/apache2/htdocs/
RUN mv /usr/local/apache2/htdocs/httpd.conf /usr/local/apache2/conf/httpd.conf
RUN cd /usr/local/apache2/htdocs/Elm && elm make ./src/Main.elm --optimize --output=../js/main.js && uglifyjs --output ../js/main.min.js --compress --mangle -- ../js/main.js  
RUN rm -rf /usr/loc/apache2/htdocs/Elm/*
RUN rm -rf /usr/loc/apache2/htdocs/Elm

EXPOSE 80