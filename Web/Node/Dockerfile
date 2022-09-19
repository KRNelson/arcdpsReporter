FROM node

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
RUN mkdir /etc/logs
RUN chmod +777 /etc/logs

COPY package.json ./
RUN npm install package.json
RUN npm install -g typescript@latest

COPY express.ts .
COPY tsconfig.json .
RUN tsc --project tsconfig.json

# If you are building your code for production
# RUN npm ci --only=production

EXPOSE 3000

CMD ["node", "./build/express.js"]