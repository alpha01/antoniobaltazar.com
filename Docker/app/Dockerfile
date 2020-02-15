FROM nginx:latest

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

ADD Docker/app /app
RUN chmod 755 /app/*.sh

EXPOSE 80

CMD ["/bin/sh", "/app/run-nginx.sh"]
