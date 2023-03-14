FROM httpd:bullseye

ENV NODE_HOST=localhost
ENV NODE_PORT=3000
ENV NODE_PORT_SSH=3443

COPY ./html/* /usr/local/apache2/htdocs/

# COPY httpd.conf /usr/local/apache2/conf/httpd.conf
COPY httpd-vhosts.conf /usr/local/apache2/conf/extra/httpd-vhosts.conf
# COPY httpd-ssl.conf /usr/local/apache2/conf/extra/httpd-ssl.conf

RUN sed -i \
    -e 's/^#\(Include .*httpd-ssl.conf\)/\1/' \
    -e 's/^#\(Include .*httpd-vhosts.conf\)/\1/' \
    -e 's/^#\(LoadModule .*mod_ssl.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_socache_shmcb.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_proxy.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_proxy_http.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_proxy_balancer.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_lbmethod_byrequets.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_slotmem_shm.so\)/\1/' \
    -e '$a\AddDefaultCharset utf-8' \
    conf/httpd.conf

# RUN openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj \
#     "/C=US/ST=California/L=./O=./CN=." \
#     -keyout /usr/local/apache2/conf/server.key -out /usr/local/apache2/conf/server.crt

COPY server.crt /usr/local/apache2/conf/server.crt
COPY server.key /usr/local/apache2/conf/server.key

COPY ../Elm/main.min.js /usr/local/apache2/htdocs/js/main.min.js

# RUN cd ./Elm && elm make ./src/Main.elm --optimize --output=/usr/local/apache2/htdocs/js/main.js && uglifyjs --output /usr/local/apache2/htdocs/js/main.min.js --compress --mangle -- /usr/local/apache2/htdocs/js/main.js

EXPOSE 443