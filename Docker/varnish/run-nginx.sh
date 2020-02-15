#!/bin/sh

(sleep 5 && varnishncsa -f /etc/varnish/varnishncsa_formatfile -t off) &

/usr/sbin/varnishd -F -f /etc/varnish/default.vcl -s malloc,100M -a 0.0.0.0:6081
