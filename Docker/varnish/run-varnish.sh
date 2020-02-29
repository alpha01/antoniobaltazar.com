#!/bin/sh

sed -i "s/##APP_HOST##/$APP_HOST/" backends.vcl
if [ "$?" != "0" ]; then
    echo "Unable template varnish config"
    exit 1
fi

(sleep 10 && varnishncsa -f /etc/varnish/varnishncsa_formatfile -t off) &

/usr/sbin/varnishd -F -f /etc/varnish/default.vcl -s malloc,100M -a 0.0.0.0:6081
