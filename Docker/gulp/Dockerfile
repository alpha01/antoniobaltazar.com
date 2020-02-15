FROM node:latest

ADD Docker/gulp /gulp

RUN chmod 755 /gulp/*.sh \
  && npm install --global gulp-cli \
  && npm link gulp


CMD ["/bin/sh", "/gulp/run-gulp-watch.sh"]
