FROM centos:centos7

ENV NODE_MAX_INSTANCES=1
ENV NODE_PORT=5555
ENV NODE_MAX_SESSION=1
ENV NODE_UNREGISTER_IF_STILL_DOWN_AFTER=60000
ENV NODE_APPLICATION_NAME=
ENV NODE_POLLING=5000
ENV NODE_HOST=0.0.0.0
ENV NODE_DOWN_POLLING_LIMIT=2
ENV NODE_REGISTER_CYCLE=5000


# begin baseline centos steps
RUN yum -y update                                 &&\
  yum -y install epel-release                     &&\
  yum -y install python-pip supervisor unzip jq	  &&\
  pip install yasha awscli                        &&\
  yum clean all

# PHP
RUN yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm

RUN yum -y install \
  php72 \
  php72-php-common \
  php72-php-pecl-imagick \
  php72-php-mbstring \
  php72-php-xml \
  yum clean all

# Selenium
RUN yum -y install \
  java-1.8.0-openjdk \
  xorg-x11-server-Xvfb \
  xorg-x11-utils \
  fluxbox \
  gnome-terminal \
  x11vnc	&&\
  yum clean all

RUN mkdir -p /etc/supervisor/conf.d &&\
  mkdir ~/.fluxbox                  &&\
  mkdir /opt/selenium 			    &&\
  mkdir /opt/bin      			    &&\
  mkdir -p /tests/features

ADD confs /confs
ADD scripts /scripts
RUN chmod 755 /scripts/* 	&&\
	cp /scripts/* /opt/bin/	&&\
	rm -fv /etc/supervisord.conf &&\
	rm -fv /etc/supervisord/conf.d/*


COPY confs/composer.json /tests/composer.json
WORKDIR /tests

RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar &&\
    chmod +x /usr/local/bin/wp                                              &&\
    ln -snf /usr/local/bin/wp /usr/local/bin/wp-cli                         &&\
    curl -Lo /usr/local/bin/phpunit https://phar.phpunit.de/phpunit-7.phar  &&\
    chmod +x /usr/local/bin/phpunit                                     &&\
    curl -LO https://getcomposer.org/installer							&&\
    source scl_source enable php72 										&&\
	php -d allow_url_fopen=on installer									&&\
	rm -v installer														&&\
	mv -v composer.phar /usr/local/bin/composer							&&\
	composer install


# WordPress
ARG WORDPRESS_VER

RUN curl -LO http://wordpress.org/wordpress-$WORDPRESS_VER.tar.gz	&&\
    tar xvzf wordpress-$WORDPRESS_VER.tar.gz \
        -C /var/www/html \
        --strip-components=1 \
        --exclude=readme.html \
        --exclude=license.txt \
        --exclude=wp-content/themes/twenty* \
        --exclude=wp-content/plugins/akismet \
        --exclude=wp-content/plugins/hello.php &&\
    rm -fv wordpress-$WORDPRESS_VER.tar.gz

RUN chown apache:apache /var/www/html

# copy over userspace environment enable script
COPY confs/php72/enable-php72.sh /etc/profile.d/enable-php72.sh


# Chrome
RUN cp -fv /confs/yum.repos.d/google-chrome.repo /etc/yum.repos.d/  &&\
    yum update                              &&\
    yum -y install google-chrome-stable     &&\
    yum clean all

ARG CHROME_DRIVER

RUN curl -LO https://chromedriver.storage.googleapis.com/$CHROME_DRIVER/chromedriver_linux64.zip &&\
	unzip chromedriver_linux64.zip			&&\
    mv -v chromedriver /opt/selenium/	    &&\
    ln -snf /opt/selenium/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER &&\
    rm -fv chromedriver_linux64.zip

ARG SELENIUM_BRANCH
ARG SELENIUM_VERSION

RUN curl -LO https://selenium-release.storage.googleapis.com/$SELENIUM_BRANCH/selenium-server-standalone-$SELENIUM_VERSION.jar &&\
	mv -v selenium-server-standalone-$SELENIUM_VERSION.jar /opt/selenium/selenium-server-standalone.jar

# Varnish
RUN cp -fv /confs/yum.repos.d/varnishcache_varnish41.repo /etc/yum.repos.d/  &&\
    yum update   &&\
    yum -y install varnish varnishncsa /confs/varnish/files/*.rpm &&\
    yum clean all

RUN cp -fv /confs/varnish/varnish /etc/sysconfig/varnish &&\
    cp -fv /confs/varnish/varnishncsa_formatfile /etc/varnish/varnishncsa_formatfile

# Apache
RUN yum -y install httpd psmisc &&\
    yum -y install https://www.cloudflare.com/static/misc/mod_cloudflare/centos/mod_cloudflare-el7-x86_64.latest.rpm &&\
    yum clean all

RUN mv -v /etc/httpd/conf.d/cloudflare.conf /tmp/   &&\
    rm -fv /etc/httpd/conf.d/*                      &&\
    mv -v /tmp/cloudflare.conf /etc/httpd/conf.d/   &&\
    sed -ri \
        -e 's!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g' \
        -e 's!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g' \
        /etc/httpd/conf/httpd.conf

# Nginx
RUN yum -y install nginx &&\
    yum clean all

RUN rm -fv /etc/nginx/conf.d/*  &&\
    mkdir -v /etc/nginx/ssl     &&\
    ln -sf /dev/stdout /var/log/nginx/access.log &&\
    ln -sf /dev/stderr /var/log/nginx/error.log


CMD ["/bin/bash", "/opt/bin/entry_point.sh"]
