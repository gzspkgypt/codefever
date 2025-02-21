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
LABEL maintainer="rexshi <rexshi@pgyer.com>"

# 设置非交互式模式，避免构建时交互提示
ENV DEBIAN_FRONTEND=noninteractive
ENV GO111MODULE=off

# 使用国内源以提高下载速度（可选，根据需要启用）
RUN sed -i 's|http://deb.debian.org|http://mirrors.aliyun.com|g' /etc/apt/sources.list && \
    sed -i 's|http://security.debian.org|http://mirrors.aliyun.com|g' /etc/apt/sources.list

# 更新并安装必要的依赖，分步处理，减少一次性失败风险
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        apt-utils \
        wget \
        curl \
        gnupg \
        lsb-release \
        dirmngr \
        software-properties-common \
        build-essential \
        libyaml-dev \
        libzip-dev \
        git \
        golang-go \
        zip \
        sendmail \
        mailutils \
        default-mysql-client \
        vim && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 检查关键安装是否成功
RUN php -v && go version && git --version && node -v || echo "One or more dependencies failed to install."

# 安装 PHP YAML 扩展
RUN pecl install yaml && \
    echo "extension=yaml.so" > /usr/local/etc/php/conf.d/yaml.ini && \
    docker-php-ext-enable yaml

# 安装 Node.js 和 npm（使用官方推荐脚本）
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 启用容器内的 SSH 和 Cron 服务
RUN docker-service enable ssh && docker-service enable cron

# 拉取 Codefever 仓库代码
RUN mkdir -p /data/www && \
    cd /data/www && \
    git clone https://github.com/PGYER/codefever.git codefever-community && \
    cd codefever-community

# Nginx 配置
COPY ./misc/docker/vhost.conf-template /opt/docker/etc/nginx/vhost.conf

# 构建 Go 项目，确保依赖可以正确拉取
RUN cd /data/www/codefever-community/http-gateway && \
    go get gopkg.in/yaml.v2 && \
    go build -o main main.go && \
    cd /data/www/codefever-community/ssh-gateway/shell && \
    go get gopkg.in/yaml.v2 && \
    go build -o main main.go

# Codefever worker 配置
COPY misc/docker/supervisor-codefever-modify-authorized-keys.conf /opt/docker/etc/supervisor.d/codefever-modify-authorized-keys.conf
COPY misc/docker/supervisor-codefever-http-gateway.conf /opt/docker/etc/supervisor.d/codefever-http-gateway.conf

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
    chmod +x /opt/docker/etc/supervisor.d/codefever-modify-authorized-keys.conf && \
    chmod +x /opt/docker/etc/supervisor.d/codefever-http-gateway.conf && \
    cd ../application/libraries/composerlib/ && \
    php ./composer.phar install

# 配置 Cron
RUN docker-cronjob '* * * * *  sh /data/www/codefever-community/application/backend/codefever_schedule.sh'

# Entrypoint
COPY misc/docker/docker-entrypoint.sh /opt/docker/provision/entrypoint.d/20-codefever.sh
