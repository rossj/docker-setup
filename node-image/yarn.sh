#!/bin/bash -e

DIR="$PWD"
cd ../
./build.sh yarn
cd "$DIR"

# Ensure dist volume exists for usage with mounting
docker volume create --name=node-dist

exec docker run -it --rm \
    -v 'yarn-cache:/yarn-cache' \
    -v "${PWD}:/mount" \
    -v 'node-modules:/work/node_modules' \
    --entrypoint /mount/guest-scripts/yarn.sh \
    local/yarn "$@" --cache-folder /yarn-cache
