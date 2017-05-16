FROM node:6.10.2

RUN apt-get update \
  && apt-get install -y rsync \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/

RUN apt-get update \
  && apt-get install -y apt-transport-https ca-certificates \
  && apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D \
  && echo 'deb https://apt.dockerproject.org/repo debian-jessie main' > /etc/apt/sources.list.d/docker.list \
  && apt-get update \
  && apt-get install -y docker-engine inotify-tools

WORKDIR /work
ENTRYPOINT yarn
