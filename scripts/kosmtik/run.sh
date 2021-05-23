#!/bin/sh

export KOSMTIK_CONFIGPATH="/.kosmtik-config.yml"

cd /openstreetmap-carto

# Starting Kosmtik
kosmtik serve project.mml --host 0.0.0.0
# It needs Ctrl+C to be interrupted
;;
