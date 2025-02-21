# FROM webdevops/php-nginx:7.4
# MAINTAINER rexshi <rexshi@pgyer.com>

# EXPOSE 80 22
# ENV GO111MODULE=off

# RUN apt-get update -y \
# && apt-get install libyaml-dev git golang-go zip sendmail mailutils mariadb-client vim -y \
# && pecl install yaml \
# && docker-php-ext-enable yaml

# # Nodejs
# RUN cd /usr/local \
# && wget https://nodejs.org/dist/v16.15.1/node-v16.15.1-linux-x64.tar.xz \
# && tar -xf node-v16.15.1-linux-x64.tar.xz \ 
# && rm -rf node-v16.15.1-linux-x64.tar.xz \
# && mv node-v16.15.1-linux-x64 node \
# && ln -s /usr/local/node/bin/node /usr/local/bin/node \
# && ln -s /usr/local/node/bin/npm /usr/local/bin/npm \
# && ln -s /usr/local/node/bin/npx /usr/local/bin/npx \
# && ln -s /usr/local/node/bin/corepack /usr/local/bin/corepack \
# && corepack enable

# # SSH
# RUN docker-service enable ssh && docker-service enable cron

# # Codefever repo
# RUN mkdir -p /data/www \
# && cd /data/www \
# && git clone https://github.com/PGYER/codefever.git codefever-community \
# && cd codefever-community

# # Nginx
# COPY ./misc/docker/vhost.conf-template /opt/docker/etc/nginx/vhost.conf

# # Go
# RUN cd /data/www/codefever-community/http-gateway \
# && go get gopkg.in/yaml.v2 \
# && go build main.go \
# && cd /data/www/codefever-community/ssh-gateway/shell \
# && go get gopkg.in/yaml.v2 \
# && go build main.go

# # Codefever worker
# COPY misc/docker/supervisor-codefever-modify-authorized-keys.conf /opt/docker/etc/supervisor.d/codefever-modify-authorized-keys.conf
# COPY misc/docker/supervisor-codefever-http-gateway.conf /opt/docker/etc/supervisor.d/codefever-http-gateway.conf

# # Configs
# RUN useradd -rm git \
#     && mkdir /usr/local/php/bin \
#     && ln -s /usr/local/bin/php /usr/local/php/bin/php \
#     && cd /data/www/codefever-community/misc \
#     && cp ./codefever-service-template /etc/init.d/codefever \
#     && cp ../config.template.yaml ../config.yaml \
#     && cp ../env.template.yaml ../env.yaml \
#     && chmod 0777 ../config.yaml ../env.yaml \
#     && mkdir ../application/logs \
#     && chown -R git:git ../application/logs \
#     && chmod -R 0777 ../application/logs  \
#     && chmod -R 0777 ../git-storage \
#     && mkdir ../file-storage \
#     && chown -R git:git ../file-storage \
#     && chown -R git:git ../misc \
#     && chmod +x /opt/docker/etc/supervisor.d/codefever-modify-authorized-keys.conf \
#     && chmod +x /opt/docker/etc/supervisor.d/codefever-http-gateway.conf \
#     && cd ../application/libraries/composerlib/ \
#     && php ./composer.phar install

# # Cron
# RUN docker-cronjob '* * * * *  sh /data/www/codefever-community/application/backend/codefever_schedule.sh'

# # Entrypoint
# COPY misc/docker/docker-entrypoint.sh /opt/docker/provision/entrypoint.d/20-codefever.sh




FROM webdevops/php-nginx:7.4
MAINTAINER rexshi <rexshi@pgyer.com>

EXPOSE 80 22
ENV GO111MODULE=off

# 更新 APT 源，确保安装最新软件包
RUN sed -i 's|http://deb.debian.org/debian|http://mirrors.kernel.org/debian|g' /etc/apt/sources.list && apt-get update -y

# 安装必要的软件包
RUN apt-get install -y --no-install-recommends \
    libyaml-dev \
    git \
    golang-go \
    zip \
    sendmail \
    mailutils \
    mariadb-client \
    vim \
    gcc \
    make \
    autoconf \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安装 YAML 扩展（指定版本以确保兼容性）
RUN pecl install yaml-2.2.2 \
    && docker-php-ext-enable yaml

# 安装 Node.js
RUN cd /usr/local \
    && wget https://nodejs.org/dist/v16.15.1/node-v16.15.1-linux-x64.tar.xz \
    && tar -xf node-v16.15.1-linux-x64.tar.xz \
    && rm -rf node-v16.15.1-linux-x64.tar.xz \
    && mv node-v16.15.1-linux-x64 node \
    && ln -s /usr/local/node/bin/node /usr/local/bin/node \
    && ln -s /usr/local/node/bin/npm /usr/local/bin/npm \
    && ln -s /usr/local/node/bin/npx /usr/local/bin/npx \
    && ln -s /usr/local/node/bin/corepack /usr/local/bin/corepack \
    && corepack enable

# 启用 SSH 和 Cron 服务
RUN docker-service enable ssh && docker-service enable cron

# 克隆 Codefever 仓库
RUN mkdir -p /data/www \
    && cd /data/www \
    && git clone https://github.com/PGYER/codefever.git codefever-community

# 配置 Nginx
COPY ./misc/docker/vhost.conf-template /opt/docker/etc/nginx/vhost.conf

# 构建 Go 项目
RUN cd /data/www/codefever-community/http-gateway \
    && go get gopkg.in/yaml.v2 \
    && go build main.go \
    && cd /data/www/codefever-community/ssh-gateway/shell \
    && go get gopkg.in/yaml.v2 \
    && go build main.go

# 配置 Codefever worker
COPY misc/docker/supervisor-codefever-modify-authorized-keys.conf /opt/docker/etc/supervisor.d/codefever-modify-authorized-keys.conf
COPY misc/docker/supervisor-codefever-http-gateway.conf /opt/docker/etc/supervisor.d/codefever-http-gateway.conf

# 配置文件和权限处理
RUN useradd -rm git \
    && mkdir /usr/local/php/bin \
    && ln -s /usr/local/bin/php /usr/local/php/bin/php \
    && cd /data/www/codefever-community/misc \
    && cp ./codefever-service-template /etc/init.d/codefever \
    && cp ../config.template.yaml ../config.yaml \
    && cp ../env.template.yaml ../env.yaml \
    && chmod 0777 ../config.yaml ../env.yaml \
    && mkdir ../application/logs \
    && chown -R git:git ../application/logs \
    && chmod -R 0777 ../application/logs \
    && chmod -R 0777 ../git-storage \
    && mkdir ../file-storage \
    && chown -R git:git ../file-storage \
    && chown -R git:git ../misc \
    && chmod +x /opt/docker/etc/supervisor.d/codefever-modify-authorized-keys.conf \
    && chmod +x /opt/docker/etc/supervisor.d/codefever-http-gateway.conf \
    && cd ../application/libraries/composerlib/ \
    && php ./composer.phar install

# 配置 Cron
RUN docker-cronjob '* * * * *  sh /data/www/codefever-community/application/backend/codefever_schedule.sh'

# 入口脚本
COPY misc/docker/docker-entrypoint.sh /opt/docker/provision/entrypoint.d/20-codefever.sh

