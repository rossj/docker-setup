#!/bin/bash -e

# Deleting the dist directory causes container crashes if it is mounted
# This will delete all content (including hidden files)
rm -rf ./dist
mkdir -p ./dist

# Copy
cp -a ./src/. ./dist

printf 'Removing .ts files from dist\n'
find ./dist -name "*.ts" -type f -delete
printf 'Compiling .ts files\n'
./node_modules/.bin/tsc "$@"
printf 'Success!\n'
