FROM centos:7

###################################
#   AUTHOR & MAINTAINER
###################################

LABEL maintainer="Vu Nguyen Vu <vunguyenvu35@gmail.com>"
USER root
ENV HTTPD_PREFIX /usr/local/apache2
ENV HTTPD_ROOT /opt/httpd

RUN yum -y update 

###################################
#   INSTALL BUILD TZ
###################################

ENV TZ=Asia/Ho_Chi_Minh
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

###################################
#   INSTALL BUILD TOOLS
###################################

RUN yum install -y  sudo bzip2-libs bzip2 bzip2-devel ca-certificates \
        glibc gmp gnutls gmp-devel libstdc++ openldap openssl-libs \
        p11-kit readline readline-devel wget expat-devel gettext-devel \
        pcre pcre-devel openssl openssl-devel epel-release git bash \
        python-setuptools gcc gcc-c++ \
        perl-ExtUtils-MakeMaker zlib-devel curl-devel make unzip \
        libxslt-devel net-snmp-devel aspell-devel unixODBC-devel \
        libicu-devel libc-client-devel freetype-devel \
        libXpm-devel libpng-devel libvpx-devel enchant-devel \
        libcurl-devel libjpeg-turbo-devel libjpeg-devel \
        libxml2-devel pkgconfig libmcrypt-devel mariadb-devel recode-devel autoconf bison re2c \
        automake libtool nasm zlib-devel sqlite3 \
        clean all

RUN rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
RUN easy_install supervisor

###################################
#   INSTALL php-fpm 7.2
###################################

## CMake
RUN mkdir -p /tmp/cmake && \
    pushd /tmp/cmake && \
    wget 'https://cmake.org/files/v3.9/cmake-3.9.1-Linux-x86_64.sh' && \
    bash cmake-3.9.1-Linux-x86_64.sh --prefix=/usr/local --exclude-subdir && \
    popd && \
    rm -rf /tmp/cmake

## Install libzip
COPY sources/php/libzip-1.5.2.tar.gz /tmp/libzip-1.5.2.tar.gz
RUN cd /tmp && tar --extract --gzip --file libzip-1.5.2.tar.gz && \
        cd /tmp/libzip-1.5.2 && \
        mkdir build && cd build && \
        cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/libzip/1_5_2 && \
        make && make install
RUN yum install -y sqlite-devel.x86_64 oniguruma-devel
## Install PHP / PHP-FPM
RUN mkdir "/opt/php"
COPY sources/php/php-7.3.12.tar.gz /opt/php/php-7.3.12.tar.gz
RUN  cd "/opt/php" \
        && tar --extract --gzip --file php-7.3.12.tar.gz \
        && cd "/opt/php/php-7.3.12" \
        && ./buildconf --force \
        && CONFIGURE_STRING="--prefix=/etc/php \
        --with-bz2 \
        \
        --with-zlib \
        --with-libzip=/usr/local/libzip/1_5_2 \
        --disable-cgi \
        --enable-soap \
        --enable-intl \
        --with-openssl \
        --with-readline \
        --with-curl \
        --enable-ftp \
        --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
        --enable-sockets \
        --enable-pcntl --with-pspell --with-enchant --with-gettext --with-gd \
        --enable-exif --with-jpeg-dir --with-png-dir --with-freetype-dir --with-xsl \
        --enable-bcmath \
        --enable-mbstring \
        --enable-calendar \
        --enable-simplexml \
        --enable-json \
        --enable-hash \
        --enable-session \
        --enable-xml \
        --enable-wddx \
        --enable-opcache --with-pcre-regex --with-config-file-path=/etc/php/etc --with-config-file-scan-dir=/etc/php/etc/php.d \
        --enable-cli \
        --enable-maintainer-zts --with-tsrm-pthreads \
        --enable-debug \
        --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data" \
        && ./configure $CONFIGURE_STRING \
        && make && sudo make install \
        && chmod o+x /etc/php/bin/phpize \
        && chmod o+x /etc/php/bin/php-config
ENV PATH "$PATH:/etc/php/bin:/etc/php/sbin"
RUN echo "alias php='/etc/php/bin/php'" > /etc/profile.d/php.sh
RUN php -v

## Setup php-fpm
RUN mkdir /etc/php/etc/php.d && cd /etc/php/etc \
        && cp php-fpm.conf.default php-fpm.conf
ADD conf/php-fpm/php-fpm.conf /opt/php
RUN cp /opt/php/php-fpm.conf /etc/php/etc/php-fpm.d/php-fpm.conf

COPY conf/php.d/php.ini-production /etc/php/etc/php.ini
RUN cd /etc/init.d \
    && cp /opt/php/php-7.3.12/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm \
    && chmod +x /etc/init.d/php-fpm
## predis
RUN yum -y install re2c
RUN  cd /tmp \
        && git clone -b 'v0.13.3' https://github.com/redis/hiredis.git \
        && cd hiredis \
	&& make && make install
RUN cd /tmp \
        && git clone https://github.com/nrk/phpiredis.git \
        && cd phpiredis \
        && phpize && ./configure --enable-phpiredis \
        && make && make install
RUN touch /etc/php/etc/php.d/predis.ini \
        && echo 'extension=phpiredis' >> /etc/php/etc/php.d/predis.ini

## solr
COPY sources/php/solr-3dbdb7e.tar.gz /tmp/solr-3dbdb7e.tar.gz
RUN cd /tmp && tar --extract --gzip --file solr-3dbdb7e.tar.gz && \
        cd /tmp/solr-3dbdb7e && \
        phpize && \
        ./configure && \
        make && make install && \
        touch /etc/php/etc/php.d/solr.ini && \
        echo "extension=solr" >> /etc/php/etc/php.d/solr.ini

##  Install pthreads
RUN mkdir "/opt/php/pthreads" \
        && cd "/opt/php/pthreads" \
        && git clone https://github.com/krakjoe/pthreads.git . \
        && phpize && ./configure --with-php-config=/etc/php/bin/php-config && make && make install && \
        touch /etc/php/etc/php.d/pthreads.ini

###################################
#   INSTALL COMPOSER
###################################
ADD composer.phar composer.phar 
RUN chmod 755 composer.phar \
        && mv composer.phar /usr/local/bin/composer \
        && composer --version

###################################
#   INSTALL JENKINS
###################################
RUN yum update -y && yum install -y epel-release && yum install -y git curl dpkg java java-devel unzip which && yum clean all
ENV JAVA_HOME /etc/alternatives/jre_openjdk

ARG user=root
ARG group=root
ARG uid=1000
ARG gid=1000
ARG http_port=8080
ARG agent_port=50000
ARG JENKINS_HOME=/var/jenkins_home
ARG REF=/usr/share/jenkins/ref

ENV JENKINS_HOME $JENKINS_HOME
ENV JENKINS_SLAVE_AGENT_PORT ${agent_port}
ENV REF $REF

# Jenkins is run with user `jenkins`, uid = 1000
# If you bind mount a volume from the host or a data container,
# ensure you use the same uid
RUN mkdir -p $JENKINS_HOME \
  && chown ${uid}:${gid} $JENKINS_HOME

# Jenkins home directory is a volume, so configuration and build history
# can be persisted and survive image upgrades
VOLUME $JENKINS_HOME

# $REF (defaults to `/usr/share/jenkins/ref/`) contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
RUN mkdir -p ${REF}/init.groovy.d

# Use tini as subreaper in Docker container to adopt zombie processes
ARG TINI_VERSION=v0.16.1
COPY tini_pub.gpg ${JENKINS_HOME}/tini_pub.gpg
RUN curl -fsSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-$(dpkg --print-architecture) -o /sbin/tini \
  && curl -fsSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-$(dpkg --print-architecture).asc -o /sbin/tini.asc \
  && gpg --no-tty --import ${JENKINS_HOME}/tini_pub.gpg \
  && gpg --verify /sbin/tini.asc \
  && rm -rf /sbin/tini.asc /root/.gnupg \
  && chmod +x /sbin/tini

# jenkins version being bundled in this docker image
ARG JENKINS_VERSION
ENV JENKINS_VERSION ${JENKINS_VERSION:-2.204.1}
RUN echo ${JENKINS_VERSION}

# jenkins.war checksum, download will be validated using it
ARG JENKINS_SHA=12b9ebbf9eb1cd1deab0d11512511bcd80a5d3a754dffab54dd6385d788d5284

# Can be used to customize where jenkins.war get downloaded from
ARG JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war

# could use ADD but this one does not check Last-Modified header neither does it allow to control checksum
# see https://github.com/docker/docker/issues/8331
RUN curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war \
  && echo "${JENKINS_SHA}  /usr/share/jenkins/jenkins.war" | sha256sum -c -

ENV JENKINS_UC https://updates.jenkins.io
ENV JENKINS_UC_EXPERIMENTAL=https://updates.jenkins.io/experimental
ENV JENKINS_INCREMENTALS_REPO_MIRROR=https://repo.jenkins-ci.org/incrementals
RUN chown -R ${user} "$JENKINS_HOME" "$REF"

# for main web interface:
EXPOSE ${http_port}

# will be used by attached slave agents:
EXPOSE ${agent_port}

ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

USER ${user}

COPY jenkins-support /usr/local/bin/jenkins-support
COPY jenkins.sh /usr/local/bin/jenkins.sh
COPY tini-shim.sh /bin/tini

# from a derived Dockerfile, can use `RUN plugins.sh active.txt` to setup $REF/plugins from a support bundle
COPY plugins.sh /usr/local/bin/plugins.sh
COPY install-plugins.sh /usr/local/bin/install-plugins.sh

# Working dir
WORKDIR $JENKINS_HOME

# Run
COPY docker-entrypoint.sh /usr/local/bin/
RUN sed -i -e 's/\r$//' /usr/local/bin/docker-entrypoint.sh
COPY supervisord.conf /etc/supervisor/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
