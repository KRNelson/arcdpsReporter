FROM node


# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)

RUN mkdir /etc/logs
RUN chmod +777 /etc/logs

COPY package.json ./
RUN npm install package.json

EXPOSE 3000

# If you are building your code for production
# RUN npm ci --only=production

COPY express.ts .

# CMD ["node", "node.js"]
CMD ["npm", "start"]