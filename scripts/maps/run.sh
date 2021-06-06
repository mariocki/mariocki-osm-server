#!/bin/bash

set -x

# Clean /tmp
rm -rf /tmp/*

compgen -e | xargs -I @ bash -c 'printf "s|\${%q}|%q|g\n" "@" "$@"' | sed -f /dev/stdin /etc/munin/munin.conf-orig >/etc/munin/munin.conf
compgen -e | xargs -I @ bash -c 'printf "s|\${%q}|%q|g\n" "@" "$@"' | sed -f /dev/stdin /usr/local/bin/openstreetmap-tiles-update-expire-orig >/usr/local/bin/openstreetmap-tiles-update-expire
chmod a+x /usr/local/bin/openstreetmap-tiles-update-expire

cd /openstreetmap-carto
carto project.mml >mapnik.xml 2>/dev/null

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

cd /var/www/html
npm install && npm run build && npm start &

# Initialize Apache
service rsyslog restart
service munin restart
service munin-node restart
service apache2 restart
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
