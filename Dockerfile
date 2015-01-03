FROM hpess/chef:latest
MAINTAINER Paul Cooke <paul.cooke@hp.com>, Karl Stoney <karl.stoney@hp.com>

# Installed the stuff for building from source
RUN yum -y install gcc gcc-c++ make zlib-devel pcre-devel openssl-devel && \
    yum -y clean all

# Build nginx from source
RUN nginxVersion="1.7.9" && \
    cd /usr/local/src && \
    wget --quiet http://nginx.org/download/nginx-$nginxVersion.tar.gz && \
    tar -xzf nginx-$nginxVersion.tar.gz && \
    ln -sf nginx-$nginxVersion nginx && \
    cd nginx && \
    ./configure \
      --user=hpess                          \
      --group=hpess                         \
      --prefix=/etc/nginx                   \
      --sbin-path=/usr/sbin/nginx           \
      --conf-path=/etc/nginx/nginx.conf     \
      --pid-path=/var/run/nginx.pid         \
      --lock-path=/var/run/nginx.lock       \
      --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/nginx/access.log \
      --with-http_gzip_static_module        \
      --with-http_stub_status_module        \
      --with-http_ssl_module                \
      --with-pcre                           \
      --with-file-aio                       \
      --with-http_realip_module             \
      --without-http_scgi_module            \
      --without-http_uwsgi_module           \
      --without-http_fastcgi_module      && \
    make && \
    make install && \
    rm -rf /usr/local/src/nginx*

# Setup directories and ownership, as well as allowing nginx to bind to low ports
RUN mkdir -p /var/log/nginx && \
    mkdir -p /var/run/nginx && \
    chown -R hpess:hpess /var/log/nginx && \
    chown -R hpess:hpess /var/run/nginx && \
    chown -R hpess:hpess /etc/nginx && \
    setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx

EXPOSE 80
EXPOSE 443

ENV chef_node_name nginx.docker.local
ENV chef_run_list nginx 

COPY services/* /etc/supervisord.d/
COPY cookbooks/ /chef/cookbooks/
ENV HPESS_ENV nginx
