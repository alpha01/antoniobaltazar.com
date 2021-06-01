FROM node:12

ADD run-gulp-watch.sh /gulp/run-gulp-watch.sh

RUN chmod 755 /gulp/*.sh \
  && npm install --global gulp-cli \
  && mkdir /build \
  && chmod -R 775 /build \
  && useradd -u 998 -m -g 0 jenkins

CMD ["/bin/sh", "/gulp/run-gulp-watch.sh"]
