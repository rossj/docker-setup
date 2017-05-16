FROM node:6.10.2

RUN echo 'Doing node-image stuff...'

WORKDIR /code
COPY package.json .
COPY yarn.lock .
RUN yarn install --pure-lockfile

COPY . .

RUN ./guest-scripts/build.sh
WORKDIR /code/dist
