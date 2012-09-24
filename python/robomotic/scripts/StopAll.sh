#!/usr/bin/env bash
#HOME="/home/guiplug"
MAX="${HOME}/EmmaSWAPdb/python/lagarto/lagarto-max/lagarto-max.py"
SWAP="${HOME}/EmmaSWAPdb/python/lagarto/lagarto-swap/lagarto-swap.py"
ARG1="$(ps auxww | grep 'python ${MAX}'| egrep -v grep | awk '{print $2}')"
ARG2="$(ps auxww | grep 'python ${SWAP}'| egrep -v grep | awk '{print $2}')"
PYTHONPROCS="$(ps auxww | grep 'python '| egrep -v grep | awk '{print $2}')"

if [ -z "$PYTHONPROCS" ]; then 
  echo "SERVICE NOT RUNNING"
else
  echo "SERVICE STOPPING"
  ARRPROCS=$(echo $PYTHONPROCS | tr " " "\n")
  for x in $ARRPROCS
  do
    kill $x
  done
fi
