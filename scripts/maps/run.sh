#!/bin/bash

set -x

# Clean /tmp
rm -rf /tmp/*

cd /openstreetmap-carto
carto project.mml >mapnik.xml

# Configure Apache CORS
if [ "$ALLOW_CORS" == "enabled" ] || [ "$ALLOW_CORS" == "1" ]; then
    echo "export APACHE_ARGUMENTS='-D ALLOW_CORS'" >>/etc/apache2/envvars
fi

# Initialize Apache
service rsyslog restart
service munin restart
service munin-node restart
service apache2 restart

# Configure renderd threads
sed -i -E "s/num_threads=[0-9]+/num_threads=${THREADS:-4}/g" /usr/local/etc/renderd.conf

# start cron job to trigger consecutive updates
/etc/init.d/cron start

# Run while handling docker stop's SIGTERM
stop_handler() {
    kill -TERM "$child"
}
trap stop_handler SIGTERM

sudo -u renderer renderd -f -c /usr/local/etc/renderd.conf &
child=$!
wait "$child"

exit 0
