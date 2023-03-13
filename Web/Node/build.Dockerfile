FROM node:16.17.1-alpine
RUN npm install -g typescript@latest
RUN npm install -g uglify-js

# COPY package.json ./
# RUN npm install package.json

# COPY express.ts .
# COPY tsconfig.json .
# RUN tsc --project tsconfig.json
