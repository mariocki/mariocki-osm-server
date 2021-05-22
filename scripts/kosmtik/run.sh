#!/bin/sh

  # Creating default Kosmtik settings file
  if [ ! -e ".kosmtik-config.yml" ]; then
    cp /tmp/.kosmtik-config.yml .kosmtik-config.yml
  fi
  export KOSMTIK_CONFIGPATH=".kosmtik-config.yml"

  # Starting Kosmtik
  kosmtik serve project.mml --host 0.0.0.0
  # It needs Ctrl+C to be interrupted
  ;;
