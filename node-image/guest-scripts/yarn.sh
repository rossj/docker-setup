#!/bin/bash -e

# Copy package.json and yarn.lock from host
cp -p /mount/package.json . || echo 'Could not find package.json'
cp -p /mount/yarn.lock . || echo 'Could not find yarn.lock'

# Run the yarn command
yarn "$@"

# Copy any node_modules stuff that host needs

cd node_modules
rsync -rtuv --relative --delete --links \
  .bin/ \
  @types/ \
  typescript/ \
  **/*.d.ts \
  /mount/node_modules/ || echo 'Not all things were rsyncd'
cd ../

# Copy any files that host needs to commmit
cp -p package.json yarn.lock /mount/