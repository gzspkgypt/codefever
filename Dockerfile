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






# 使用 webdevops/php-nginx:7.4 基础镜像
FROM webdevops/php-nginx:7.4

# 设置环境变量，避免安装过程中交互
ENV DEBIAN_FRONTEND=noninteractive

# 更新并安装必要的软件包
RUN set -eux; \
    # 检查是否存在 apt 源文件，并替换为国内镜像
    if [ -f /etc/apt/sources.list ]; then \
        sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' /etc/apt/sources.list && \
        sed -i 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' /etc/apt/sources.list; \
    fi; \
    # 指定 APT 使用旧版源（防止镜像中的证书过期）
    echo "Acquire::Check-Valid-Until false;" >> /etc/apt/apt.conf.d/99-ignore-valid-until; \
    apt-get update -y; \
    # 尝试安装必要的软件包
    apt-get install -y --no-install-recommends \
        libyaml-dev \
        git \
        golang-go \
        zip \
        sendmail \
        mailutils \
        mariadb-client \
        vim \
        wget \
        gcc \
        make \
        autoconf; \
    # 清理缓存
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# 安装 YAML 扩展
RUN pecl install yaml && docker-php-ext-enable yaml

# 验证 YAML 扩展是否正常加载
RUN php -m | grep yaml

# 安装 Node.js 和 npm
RUN wget -qO- https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g corepack && \
    corepack enable && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 下载 Codefever 源码
RUN mkdir -p /data/www && \
    cd /data/www && \
    git clone https://github.com/PGYER/codefever.git codefever-community

# 编译 Codefever 的 Go 程序
RUN cd /data/www/codefever-community/http-gateway && \
    go get gopkg.in/yaml.v2 && \
    go build -o main main.go && \
    cd /data/www/codefever-community/ssh-gateway/shell && \
    go get gopkg.in/yaml.v2 && \
    go build -o main main.go

# 设置文件权限和配置初始化
RUN useradd -rm git && \
    mkdir -p /usr/local/php/bin && \
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
    php ./composer.phar install

# 配置定时任务（Cron）
RUN echo '* * * * *  sh /data/www/codefever-community/application/backend/codefever_schedule.sh' > /etc/cron.d/codefever-cron && \
    chmod 0644 /etc/cron.d/codefever-cron && \
    crontab /etc/cron.d/codefever-cron

# 启用 SSH 和 Cron 服务
RUN docker-service enable ssh && docker-service enable cron

# 配置 Nginx 虚拟主机
COPY ./misc/docker/vhost.conf-template /opt/docker/etc/nginx/vhost.conf

# 配置启动脚本
COPY ./misc/docker/docker-entrypoint.sh /opt/docker/provision/entrypoint.d/20-codefever.sh

# 暴露必要的端口
EXPOSE 80 22
