#!/bin/bash -e

send_signal () {
  printf 'Notifying services of change...\n'
  local containers=`docker ps | awk '{ print $1,$2 }' | grep node-image | awk '{print $1 }'`
  for container in $containers; do
    # We don't know the actual container name... so guess a couple
    docker exec "$container" bash -c 'kill -SIGUSR2 1' 2>&1
  done
}

# Rsyncs non-typescript files from /mount/src to /code/dist
copy_non_ts_src () {
  printf 'Copying mounted non-ts src to dist\n'
  rsync -rtu "$@" --links \
    --exclude='*.ts' \
    /mount/src/ ./dist/
}

# Rsyncs typescript files from /mount/src to /code/src,
# so they can be compiled into /code/dist
copy_ts_src () {
  printf 'Copying mounted non-ts src to dist\n'
  rsync -rtu "$@" --links \
    --include='*/' \
    --include='*.ts' \
    --include='tsconfig.json' \
    --exclude='*' \
    /mount/src /mount/tsconfig.json ./
}

# Watches for events on non-ts files
watch_src () {
  while inotifywait -q -e modify -e create -e delete -r /mount/src/; do
    printf 'Detected src change...\n'
    copy_non_ts_src -v
    copy_ts_src --delete -v
  done
}

watch_src () {
  while file=$(inotifywait -q -e modify -e create -e delete -r --format "%w%f" /mount/src/); do
    local EXT=${file##*.}
    if [ $EXT = "ts" ]; then
      printf 'Detected ts src change...\n'
      copy_ts_src --delete -v
      (compile_typescript && send_signal) || true
    else
      printf 'Detected non-ts src change...\n'
      copy_non_ts_src -v
      send_signal
    fi
  done
}

compile_typescript () {
  printf 'Compiling .ts files...\n' && ./node_modules/.bin/tsc && printf 'Success!\n'
}

# TODO: RDJ: For now, tsc watch can't be used reliably on linux
# see https://github.com/Microsoft/TypeScript/issues/11564
watch_typescript () {
  printf 'Watching .ts files...\n'
  ./node_modules/.bin/tsc --watch
}

watch_dist () {
  while inotifywait -q -e modify -e create -e delete -r ./dist/; do
    send_signal
  done
}

copy_non_ts_src --delete
copy_ts_src --delete
compile_typescript || printf 'WARNING: Error compiling typescript!\n'
send_signal

if [ -n "$1" ]; then
  #watch_dist &
  watch_src &
  wait
fi
