FROM node

ENV MYSQL_ROOT_PASSWORD_FILE=/run/secrets/root_password
ENV MYSQL_ROOT_HOST_FILE=/run/secrets/host
ENV MYSQL_DATABASE_FILE=/run/secrets/database
ENV MYSQL_USER_FILE=/run/secrets/user
ENV MYSQL_PASSWORD_FILE=/run/secrets/password

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY server.crt server.crt
COPY server.key server.key


COPY ./build/express.min.js .
COPY package.json .

RUN npm install package.json

# If you are building your code for production
# RUN npm ci --only=production

EXPOSE 3443

CMD ["node", "express.min.js"]
