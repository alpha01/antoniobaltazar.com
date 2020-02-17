FROM nginx:latest

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log \
  && rm -rvf /usr/share/nginx/html/*

ADD . /usr/share/nginx/html

EXPOSE 80

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]

