#!/bin/bash -e

# Load all variables in dev.env
set -a
source dev.env
set +a

set -a
source VERSION.env
set +a

export TAG="${CURR}"

# Flags
# WATCH implies MOUNT
MOUNT=false
WATCH=false

handle_option () {
  case "$1" in
    --mount)    MOUNT=true
                ;;
    --watch)    WATCH=true
                printf 'WATCH implies MOUNT\n'
                MOUNT=true
                ;;
    --tag=*)    TAG=${1#--tag=}
  esac
}

YMLS='-f docker-compose.yml -f docker-compose.dev.yml'

# Handle any args before the service name
while true; do
  if [[ $1 == -* ]]; then
    handle_option "$1"
    shift
  else
    break
  fi
done

# Remove any existing test containers
docker-compose $YMLS stop
docker-compose $YMLS rm -f -v

if [ "$MOUNT" == true ]; then
  cd node-image
  ./yarn.sh install --pure-lockfile
  cd ../
  YMLS="${YMLS} -f docker-compose.dev.mount.yml"
fi

if [ "$WATCH" == true ]; then
  YMLS="${YMLS} -f  docker-compose.dev.mount.watch.yml"
fi

exec docker-compose $YMLS up --force-recreate
