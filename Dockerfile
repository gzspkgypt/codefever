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






# # 使用 Ubuntu 20.04 作为基础镜像
# FROM ubuntu:20.04

# # 维护者信息
# LABEL maintainer="rexshi <rexshi@pgyer.com>"

# # 设置环境变量
# ENV DEBIAN_FRONTEND=noninteractive \
#     TZ=Asia/Shanghai \
#     NODE_VERSION=16.20.0

# # 替换为国内镜像源并安装必要的软件包
# RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list && \
#     sed -i 's|http://security.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list && \
#     apt-get update -y && apt-get install -y --no-install-recommends \
#     software-properties-common \
#     tzdata \
#     curl \
#     zip \
#     unzip \
#     git \
#     build-essential \
#     libyaml-dev \
#     libzip-dev \
#     golang-go \
#     cron \
#     vim \
#     mysql-client \
#     php-cli \
#     php-fpm \
#     php-mysql \
#     php-zip \
#     php-mbstring \
#     php-xml \
#     php-bcmath \
#     php-curl \
#     php-soap \
#     sendmail && \
#     ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
#     echo "Asia/Shanghai" > /etc/timezone && \
#     apt-get clean && rm -rf /var/lib/apt/lists/*

# # 安装 Node.js 和 npm（通过清华大学镜像）
# RUN curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz -o node.tar.xz && \
#     mkdir -p /usr/local/lib/nodejs && \
#     tar -xJf node.tar.xz -C /usr/local/lib/nodejs --strip-components=1 && \
#     rm node.tar.xz && \
#     ln -s /usr/local/lib/nodejs/bin/node /usr/local/bin/node && \
#     ln -s /usr/local/lib/nodejs/bin/npm /usr/local/bin/npm && \
#     ln -s /usr/local/lib/nodejs/bin/npx /usr/local/bin/npx

# # 验证 Node.js 和 npm 是否正确安装
# RUN node -v && npm -v

# # 拉取代码仓库
# RUN mkdir -p /data/www && \
#     git clone https://github.com/PGYER/codefever.git /data/www/codefever-community

# # 安装 Composer
# RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# # 构建 Go 项目
# RUN cd /data/www/codefever-community/http-gateway && \
#     go get -d ./... && \
#     go build -o main main.go && \
#     cd /data/www/codefever-community/ssh-gateway/shell && \
#     go get -d ./... && \
#     go build -o main main.go

# # 配置 Codefever
# RUN useradd -rm git && \
#     mkdir -p /usr/local/php/bin && \
#     ln -s /usr/bin/php /usr/local/php/bin/php && \
#     cd /data/www/codefever-community/misc && \
#     cp ./codefever-service-template /etc/init.d/codefever && \
#     cp ../config.template.yaml ../config.yaml && \
#     cp ../env.template.yaml ../env.yaml && \
#     chmod 0777 ../config.yaml ../env.yaml && \
#     mkdir -p ../application/logs && \
#     chown -R git:git ../application/logs && \
#     chmod -R 0777 ../application/logs && \
#     chmod -R 0777 ../git-storage && \
#     mkdir -p ../file-storage && \
#     chown -R git:git ../file-storage && \
#     chown -R git:git ../misc

# # 安装 PHP 依赖（通过 Composer）
# RUN cd /data/www/codefever-community/application/libraries/composerlib && \
#     composer install --no-dev --ignore-platform-reqs

# # 安装和配置 Cron 任务
# RUN echo "* * * * * root sh /data/www/codefever-community/application/backend/codefever_schedule.sh" > /etc/cron.d/codefever-cron && \
#     chmod 0644 /etc/cron.d/codefever-cron && \
#     crontab /etc/cron.d/codefever-cron

# # 配置 Entrypoint 脚本
# COPY misc/docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
# RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# # 启动 Cron 服务
# RUN service cron start

# # 暴露端口
# EXPOSE 80 22

# # 设置启动脚本
# CMD ["php-fpm"]





# 使用 Ubuntu 20.04 作为基础镜像  
FROM ubuntu:20.04  
  
LABEL maintainer="rexshi <rexshi@pgyer.com>"  
  
# 暴露端口  
EXPOSE 80 22  
  
# 设置环境变量  
ENV DEBIAN_FRONTEND=noninteractive \  
    TZ=Asia/Shanghai \  
    GO111MODULE=off  
  
# 设置时区  
RUN ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \  
    echo "${TZ}" > /etc/timezone  
  
# 安装必要的软件包  
RUN apt-get update && apt-get install -y \  
    software-properties-common \  
    curl \  
    wget \  
    git \  
    vim \  
    unzip \  
    zip \  
    sendmail \  
    mailutils \  
    mariadb-client \  
    build-essential \  
    libyaml-dev \  
    libzip-dev \  
    libonig-dev \  
    libxml2-dev \  
    libssl-dev \  
    ca-certificates \  
    gnupg2 \  
    lsb-release \  
    openssh-server \  
    cron \  
    supervisor \  
    nginx \  
    php7.4 \  
    php7.4-fpm \  
    php7.4-cli \  
    php7.4-dev \  
    php-pear \  
    php7.4-mysql \  
    php7.4-zip \  
    php7.4-mbstring \  
    php7.4-xml \  
    php7.4-bcmath \  
    php7.4-curl \  
    php7.4-soap \  
    php7.4-gd \  
    php7.4-intl \  
    php7.4-ldap \  
    golang-go  
  
# 安装 PECL 扩展 yaml  
RUN pecl channel-update pecl.php.net && \  
    pecl install yaml && \  
    echo "extension=yaml.so" > /etc/php/7.4/mods-available/yaml.ini && \  
    phpenmod yaml  
  
# 安装 Node.js（使用官方源）  
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \  
    apt-get install -y nodejs  
  
# 启用 corepack  
RUN corepack enable  
  
# 配置 SSH 服务  
RUN mkdir -p /var/run/sshd && \  
    echo 'root:password' | chpasswd && \  
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config  
  
# 克隆 Codefever 仓库  
RUN mkdir -p /data/www && \  
    git clone https://github.com/PGYER/codefever.git /data/www/codefever-community  
  
# 设置工作目录  
WORKDIR /data/www/codefever-community  
  
# 构建 Go 项目  
RUN cd http-gateway && \  
    go get gopkg.in/yaml.v2 && \  
    go build -o main main.go && \  
    cd ../ssh-gateway/shell && \  
    go get gopkg.in/yaml.v2 && \  
    go build -o main main.go  
  
# 安装 Composer  
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer  
  
# 配置 Composer 镜像源（可选）  
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/  
  
# 安装 PHP 依赖（通过 Composer）  
RUN cd application/libraries/composerlib && \  
    composer install --no-dev --ignore-platform-reqs  
  
# 复制 Nginx 配置  
COPY misc/docker/vhost.conf-template /etc/nginx/sites-available/default  
  
# 复制 Supervisor 配置文件  
COPY misc/docker/supervisor-codefever-modify-authorized-keys.conf /etc/supervisor/conf.d/codefever-modify-authorized-keys.conf  
COPY misc/docker/supervisor-codefever-http-gateway.conf /etc/supervisor/conf.d/codefever-http-gateway.conf  
  
# 设置 Supervisor 配置文件权限  
RUN chmod 644 /etc/supervisor/conf.d/codefever-modify-authorized-keys.conf && \  
    chmod 644 /etc/supervisor/conf.d/codefever-http-gateway.conf  
  
# 配置 Codefever  
RUN useradd -rm git && \  
    mkdir -p /usr/local/php/bin && \  
    ln -s /usr/bin/php /usr/local/php/bin/php && \  
    cp config.template.yaml config.yaml && \  
    cp env.template.yaml env.yaml && \  
    chmod 0777 config.yaml env.yaml && \  
    mkdir -p application/logs && \  
    chown -R git:git application/logs && \  
    chmod -R 0777 application/logs && \  
    chmod -R 0777 git-storage && \  
    mkdir -p file-storage && \  
    chown -R git:git file-storage && \  
    chown -R git:git misc && \  
    cp misc/codefever-service-template /etc/init.d/codefever  
  
# 设置 Cron 任务  
RUN echo "* * * * * root sh /data/www/codefever-community/application/backend/codefever_schedule.sh" > /etc/cron.d/codefever-cron && \  
    chmod 0644 /etc/cron.d/codefever-cron  
  
# 确保权限正确  
RUN chown -R www-data:www-data /data/www  
  
# 复制 Entrypoint 脚本并设置权限  
COPY misc/docker/docker-entrypoint.sh /usr/local/bin/entrypoint.sh  
RUN chmod +x /usr/local/bin/entrypoint.sh  
  
# 设置 Entrypoint  
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]  
  
# 默认命令  
CMD ["supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]  
