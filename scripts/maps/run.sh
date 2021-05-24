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

# Initialize Apache
service rsyslog restart
service munin restart
service munin-node restart
service apache2 restart
service renderd restart
service cron restart

# UK
# render_list_geo.pl -n 4 -z 7 -Z 9 -x -9.5 -X 2.72 -y 49.39 -Y 61.26 -m ajt

# London
# render_list_geo.pl -f -n 4 -z 14 -Z 16 -x -7.4 -X 0.57 -y 51.29 -Y 51.8 -m ajt

# stanstead airport
# render_list_geo.pl -f -n 4 -z 6 -Z 16 -x 0.05 -X 0.42 -y 51.80 -Y 51.92 -m ajt

# manchester
# render_list_geo.pl -f -n 2 -z 8 -Z 10 -x -2.5 -X -1.99 -y 53.36 -Y 53.61 -m ajt

sleep infinity

exit 0
