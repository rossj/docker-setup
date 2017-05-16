#!/bin/bash

CPID=0
KILLED=false

trap "kill -SIGINT $CPID" SIGUSR2
trap "KILLED=true && trap - SIGTERM && kill -- -$$" SIGINT SIGTERM

sleep_inf () {
    # stall... don't exit
    sleep inf > /dev/null 2>&1 &
    CPID=$!

    wait
}

echo "Restarter: waiting for initial signal..."
sleep_inf

while [ "$KILLED" = false ]
do
  "$@" &
  CPID=$!

  wait $CPID
  CODE=$?

  # Check if code indicates we got a SIGUSR2
  if [ "$KILLED" = true ]; then
    echo 'Restarter: exiting...'
    break
  elif [ $CODE -eq 140 ]; then
    echo "Restarter: restarting main process..."
    wait $CPID
  else
    echo "Restarter: main process exited with code $CODE"
    echo "Restarter: waiting for restart signal..."
    sleep_inf

  fi
done
