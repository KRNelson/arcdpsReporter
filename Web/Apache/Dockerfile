FROM httpd:bullseye

ENV NODE_HOST=node
ENV NODE_PORT=3000

# RUN apt-get install npm
RUN apt-get update
RUN apt-get install -y npm --no-install-recommends

RUN npm install -g elm@0.19.1
RUN npm install -g uglify-js

COPY ./html/* /usr/local/apache2/htdocs/
COPY ./Elm ./Elm

COPY httpd.conf /usr/local/apache2/conf/httpd.conf
COPY httpd-vhosts.conf /usr/local/apache2/conf/extra/httpd-vhosts.conf

RUN cd ./Elm && elm make ./src/Main.elm --optimize --output=/usr/local/apache2/htdocs/js/main.js && uglifyjs --output /usr/local/apache2/htdocs/js/main.min.js --compress --mangle -- /usr/local/apache2/htdocs/js/main.js

RUN rm -rf ./Elm/*
RUN rm -rf ./Elm

EXPOSE 80
