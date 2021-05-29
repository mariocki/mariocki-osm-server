#!/bin/bash

export KOSMTIK_CONFIGPATH="/.kosmtik-config.yml"

cd /openstreetmap-carto

# Starting Kosmtik
kosmtik serve project.mml --host 0.0.0.0

while [[ true ]]; do

  kosmtik serve project.mml --host 0.0.0.0

done

exit 0
;;
