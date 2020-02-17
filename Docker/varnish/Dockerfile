FROM varnish:6.0.5

ADD conf /varnish
ADD run-varnish.sh /varnish/run-varnish.sh

RUN chmod 755 /varnish/*.sh \
  && cp -v /varnish/*.vcl /etc/varnish/ \
  && cp -v /varnish/varnishncsa_formatfile /etc/varnish/

EXPOSE 6081

CMD ["/bin/sh", "/varnish/run-varnish.sh"]
