#!/bin/bash

set -x

# Clean /tmp
rm -rf /tmp/*

cd /openstreetmap-carto
carto project.mml >mapnik.xml 2>/dev/null

# Configure renderd threads
sed -i -E "s/num_threads=[0-9]+/num_threads=${THREADS:-4}/g" /etc/renderd.conf

# Initialize Apache
service rsyslog restart
service munin-node restart
service renderd restart
service cron stop

chsum1=""

cd /openstreetmap-carto

while [[ true ]]; do

    if ! pgrep -x renderd >/dev/null 2>&1; then
        echo $(date) "renderd stopped ... restarting " | logger
        service renderd restart
    fi

    sleep 5
done

exit 0
