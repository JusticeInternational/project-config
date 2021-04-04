#!/bin/bash

_term() { 
  echo "Caught SIGTERM signal!" 
  kill -TERM "$child" 2>/dev/null
}

_http() {
    echo "Attempting to start on ${PORT}"
    while true ; do
    nc -l -p $PORT -c 'echo -e "HTTP/1.1 200 OK\n\n $(date)"';
    _return=$?
    test ${_return} -gt 128 && break
    done
}

export JOB_MODE="${JOB_MODE:-false}"

trap _term SIGTERM

if [ "${JOB_MODE}" = "false" ]; then
  _http &
  child=$!
  echo "waiting on ${child}"
  wait "${child}"
else
  echo "job executed"
fi
exit 0