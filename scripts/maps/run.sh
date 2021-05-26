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

# Configure renderd threads
sed -i -E "s/num_threads=[0-9]+/num_threads=${THREADS:-4}/g" /usr/local/etc/renderd.conf

if [ ! -f /var/lib/mod_tile/.osmosis/state.txt ]; then
    sudo -u renderer /usr/local/bin/openstreetmap-tiles-update-expire "$(</var/lib/mod_tile/replication_timestamp.txt)"
fi

# do this here as its a volume
chown munin.www-data /var/lib/munin
chmod g+w /var/lib/munin

# Initialize Apache
service rsyslog restart
service munin restart
service munin-node restart
service apache2 restart
service renderd restart
service cron restart

sudo -u renderer munin-cron

# UK
# render_list_geo.pl -n 4 -z 7 -Z 9 -x -9.5 -X 2.72 -y 49.39 -Y 61.26 -m ajt

# London
# render_list_geo.pl -f -n 2 -z 8 -Z 16 -x -7.4 -X 0.57 -y 51.29 -Y 51.8 -m ajt

# stanstead airport
# render_list_geo.pl -f -n 4 -z 6 -Z 16 -x 0.05 -X 0.42 -y 51.80 -Y 51.92 -m ajt

# manchester
# render_list_geo.pl -f -n 2 -z 8 -Z 16 -x -2.5 -X -1.99 -y 53.36 -Y 53.61 -m ajt

chsum1=""

cd /openstreetmap-carto

while [[ true ]]; do
    chsum2=$(md5deep -r -l . | sort | md5sum)
    if [[ $chsum1 != $chsum2 ]]; then
        carto project.mml >mapnik.xml
        service renderd restart
        chsum1=$chsum2
    fi
    sleep 5
done

exit 0
