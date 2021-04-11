#!/bin/bash

_term() { 
  echo "Caught SIGTERM signal!" 
  kill -TERM "$child" 2>/dev/null
}

export JOB_MODE="${JOB_MODE:-false}"

trap _term SIGTERM

if [ "${JOB_MODE}" = "false" ]; then
  node /app/server.js &
  child=$!
  echo "waiting on ${child}"
  wait "${child}"
else
  echo "job executed"
fi
exit 0