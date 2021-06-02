#!/bin/bash

rm -rf /tmp/xx
render_list_geo.pl -z 3 -Z 16 -x -9.5 -X 2.72 -y 49.39 -Y 61.26 -m ajt >/tmp/cmds

while read a; do

  echo "executing: " $a
  eval "$a >>/tmp/xx 2>&1 &"
  PID=$!
  echo "PID is " $PID

  while kill -0 $PID 2>/dev/null; do
    if grep -q socket /tmp/xx; then
      echo "process died, restarting"
      kill -9 $PID
      sleep 1

      mv /tmp/xx /tmp/xx-$PID

      echo "executing: " $a
      eval "$a >/tmp/xx 2>&1 &"
      PID=$!
      echo "new PID is " $PID
    fi
    sleep 5
  done

  sleep 5
done </tmp/cmds
