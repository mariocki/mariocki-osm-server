#!/bin/bash

set -x

# Clean /tmp
rm -rf /tmp/*

compgen -e | xargs -I @ bash -c 'printf "s|\${%q}|%q|g\n" "@" "$@"' | sed -f /dev/stdin /etc/munin/munin.conf-orig >/etc/munin/munin.conf
compgen -e | xargs -I @ bash -c 'printf "s|\${%q}|%q|g\n" "@" "$@"' | sed -f /dev/stdin /usr/local/bin/openstreetmap-tiles-update-expire-orig >/usr/local/bin/openstreetmap-tiles-update-expire
chmod a+x /usr/local/bin/openstreetmap-tiles-update-expire

cd /openstreetmap-carto/style
./merge.sh
cd ..
carto -q project.mml >mapnik.xml 

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

cd /var/www/html && npm install && npm start &

# just in case
mkdir -p /var/lib/mod_tile/ajt
mkdir -p /var/lib/mod_tile/rwy
chown -R renderer /var/lib/mod_tile

# fudge to force mod_tile to not re-render low level zooms 
find /var/lib/mod_tile/ajt/[123456789] -type f -exec touch {} \;
find /var/lib/mod_tile/ajt/1[012] -type f -exec touch {} \;

# Initialize Apache
service rsyslog stop
service munin stop
service munin-node stop
apachectl stop

rm /run/rsyslogd.pid
rm /var/run/munin/munin-node.pid

service rsyslog start
service munin start
service munin-node start


source /etc/apache2/envvars && apachectl start
service renderd restart
service cron restart

sudo -u munin munin-cron &

sleep infinity

exit 0
