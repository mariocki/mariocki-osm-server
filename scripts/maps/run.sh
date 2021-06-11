#!/bin/bash

set -x

# Clean /tmp
rm -rf /tmp/*

compgen -e | xargs -I @ bash -c 'printf "s|\${%q}|%q|g\n" "@" "$@"' | sed -f /dev/stdin /etc/munin/munin.conf-orig >/etc/munin/munin.conf
compgen -e | xargs -I @ bash -c 'printf "s|\${%q}|%q|g\n" "@" "$@"' | sed -f /dev/stdin /usr/local/bin/openstreetmap-tiles-update-expire-orig >/usr/local/bin/openstreetmap-tiles-update-expire
chmod a+x /usr/local/bin/openstreetmap-tiles-update-expire

cd /openstreetmap-carto
carto -q project.mml >mapnik.xml &
CARTO_PID=$!

# Configure Apache CORS
if [ "$ALLOW_CORS" == "enabled" ] || [ "$ALLOW_CORS" == "1" ]; then
    echo "export APACHE_ARGUMENTS='-D ALLOW_CORS'" >>/etc/apache2/envvars
fi

# Configure renderd threads
sed -i -E "s/num_threads=[0-9]+/num_threads=${THREADS:-4}/g" /etc/renderd.conf

if [ ! -f /var/lib/mod_tile/.osmosis/state.txt ]; then
    sudo -u renderer /usr/local/bin/openstreetmap-tiles-update-expire "$(</var/lib/mod_tile/replication_timestamp.txt)"
fi

# do this here as its a volume
chown munin.www-data /var/lib/munin
chmod g+w /var/lib/munin

cd /var/www/html && npm run build && npm start &

# just in case
chown -R renderer /var/lib/mod_tile/ajt

# Initialize Apache
service rsyslog stop
rm /run/rsyslogd.pid
service rsyslog start

service munin restart
service munin-node restart
apachectl stop
while kill -0 $CARTO_PID; do
    echo "Waiting for Carto..."
    sleep 1
    # You can add a timeout here if you want
done

source /etc/apache2/envvars && apachectl start
#service renderd restart
service cron restart

sudo -u munin munin-cron &

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
