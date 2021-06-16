FROM node:11
WORKDIR /usr/src/app
COPY src/ .
RUN apt -y update
RUN apt -y install ffmpeg
RUN npm install
CMD [ "node", "server.js" ]
