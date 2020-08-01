FROM node:latest

ADD run-gulp-watch.sh /gulp/run-gulp-watch.sh

RUN chmod 755 /gulp/*.sh \
  && npm install --global gulp-cli \
  && npm link gulp \
  && useradd -u 998 jenkins


CMD ["/bin/sh", "/gulp/run-gulp-watch.sh"]
