FROM node:16.17.1-alpine

RUN npm install -g elm@0.19.1
RUN npm install -g uglify-js

COPY . .

RUN elm make ./src/Main.elm --optimize --output=main.js && uglifyjs --output main.min.js --compress --mangle -- main.js

