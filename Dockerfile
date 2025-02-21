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






# 使用基础镜像
FROM php:7.4-fpm

# 维护者信息
LABEL maintainer="rexshi <rexshi@pgyer.com>"

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    NODE_VERSION=16.20.0

# 使用官方推荐的阿里云镜像配置文件替换源
RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak && \
    echo "deb http://mirrors.aliyun.com/debian buster main contrib non-free" > /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/debian buster-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/debian-security buster/updates main contrib non-free" >> /etc/apt/sources.list

# 更新包管理器并安装所需依赖
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    dirmngr \
    build-essential \
    libyaml-dev \
    libzip-dev \
    git \
    cron \
    golang-go \
    zip \
    sendmail \
    mailutils \
    default-mysql-client \
    vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 安装 Node.js 和 npm
RUN curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz -o node.tar.xz && \
    mkdir -p /usr/local/lib/nodejs && \
    tar -xJf node.tar.xz -C /usr/local/lib/nodejs --strip-components=1 && \
    rm node.tar.xz && \
    ln -s /usr/local/lib/nodejs/bin/node /usr/local/bin/node && \
    ln -s /usr/local/lib/nodejs/bin/npm /usr/local/bin/npm && \
    ln -s /usr/local/lib/nodejs/bin/npx /usr/local/bin/npx

# 验证 Node.js 和 npm 是否正确安装
RUN node -v && npm -v

# 安装 PHP 扩展
RUN docker-php-ext-install zip && \
    pecl install yaml && \
    echo "extension=yaml.so" > /usr/local/etc/php/conf.d/yaml.ini && \
    docker-php-ext-enable yaml

# 拉取代码仓库
RUN mkdir -p /data/www && \
    cd /data/www && \
    git clone https://github.com/PGYER/codefever.git codefever-community

# 构建 Go 项目
RUN cd /data/www/codefever-community/http-gateway && \
    go get -d ./... && \
    go build -o main main.go && \
    cd /data/www/codefever-community/ssh-gateway/shell && \
    go get -d ./... && \
    go build -o main main.go

# 配置 Codefever
RUN useradd -rm git && \
    mkdir /usr/local/php/bin && \
    ln -s /usr/local/bin/php /usr/local/php/bin/php && \
    cd /data/www/codefever-community/misc && \
    cp ./codefever-service-template /etc/init.d/codefever && \
    cp ../config.template.yaml ../config.yaml && \
    cp ../env.template.yaml ../env.yaml && \
    chmod 0777 ../config.yaml ../env.yaml && \
    mkdir ../application/logs && \
    chown -R git:git ../application/logs && \
    chmod -R 0777 ../application/logs && \
    chmod -R 0777 ../git-storage && \
    mkdir ../file-storage && \
    chown -R git:git ../file-storage && \
    chown -R git:git ../misc && \
    cd ../application/libraries/composerlib/ && \
    php ./composer.phar install --no-dev

# 配置 Cron 任务
RUN echo "* * * * * root sh /data/www/codefever-community/application/backend/codefever_schedule.sh" > /etc/cron.d/codefever-cron && \
    chmod 0644 /etc/cron.d/codefever-cron && \
    crontab /etc/cron.d/codefever-cron

# 启动 Cron 服务
RUN service cron start

# 配置 Entrypoint 脚本
COPY misc/docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 暴露端口
EXPOSE 80 22

# 设置启动脚本
CMD ["php-fpm"]
