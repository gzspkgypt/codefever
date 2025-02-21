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





# Use Ubuntu 20.04 as the base image  
FROM ubuntu:20.04  
  
# Maintainer information  
LABEL maintainer="rexshi <rexshi@pgyer.com>"  
  
# Set environment variables  
ENV DEBIAN_FRONTEND=noninteractive \  
    TZ=Asia/Shanghai \  
    GO_VERSION=1.20.5 \  
    GOPROXY=https://goproxy.cn,direct \  
    GO111MODULE=on  
  
# Install necessary packages  
RUN apt-get update -y && apt-get install -y --no-install-recommends \  
    tzdata \  
    curl \  
    wget \  
    git \  
    build-essential \  
    libyaml-dev \  
    libzip-dev \  
    cron \  
    vim \  
    mysql-client \  
    php-cli \  
    php-fpm \  
    php-mysql \  
    php-zip \  
    php-mbstring \  
    php-xml \  
    php-bcmath \  
    php-curl \  
    php-soap \  
    sendmail \  
    gnupg \  
    ca-certificates \  
    openssh-client \  
    openssh-server \  
    net-tools && \  
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \  
    echo "${TZ}" > /etc/timezone && \  
    apt-get clean && rm -rf /var/lib/apt/lists/*  
  
# Install Go  
RUN wget -q https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz && \  
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \  
    rm go${GO_VERSION}.linux-amd64.tar.gz  
  
# Set Go environment variables  
ENV PATH="/usr/local/go/bin:${PATH}"  
  
# Verify Go installation  
RUN go version  
  
# Install Node.js and npm (using official source)  
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \  
    apt-get install -y nodejs  
  
# Verify Node.js and npm installation  
RUN node -v && npm -v  
  
# Pull code repository  
RUN mkdir -p /data/www && \  
    git clone https://github.com/PGYER/codefever.git /data/www/codefever-community  
  
# Build Go project: http-gateway  
WORKDIR /data/www/codefever-community/http-gateway  
RUN go env && \  
    go mod tidy && \  
    go build -v -o main main.go  
  
# Build Go project: ssh-gateway  
WORKDIR /data/www/codefever-community/ssh-gateway/shell  
RUN go env && \  
    go mod tidy && \  
    go build -v -o main main.go  
  
# Configure Codefever  
RUN useradd -rm git && \  
    mkdir -p /usr/local/php/bin && \  
    ln -s /usr/bin/php /usr/local/php/bin/php && \  
    cd /data/www/codefever-community/misc && \  
    cp ./codefever-service-template /etc/init.d/codefever && \  
    cp ../config.template.yaml ../config.yaml && \  
    cp ../env.template.yaml ../env.yaml && \  
    chmod 0777 ../config.yaml ../env.yaml && \  
    mkdir -p ../application/logs && \  
    chown -R git:git ../application/logs && \  
    chmod -R 0777 ../application/logs && \  
    chmod -R 0777 ../git-storage && \  
    mkdir -p ../file-storage && \  
    chown -R git:git ../file-storage && \  
    chown -R git:git ../misc  
  
# Install Composer  
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer  
  
# Install PHP dependencies (via Composer)  
WORKDIR /data/www/codefever-community/application/libraries/composerlib  
RUN composer install --no-dev --ignore-platform-reqs  
  
# Install and configure Cron task  
RUN echo "* * * * * root sh /data/www/codefever-community/application/backend/codefever_schedule.sh" > /etc/cron.d/codefever-cron && \  
    chmod 0644 /etc/cron.d/codefever-cron  
  
# Copy Entrypoint script  
COPY misc/docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh  
RUN chmod +x /usr/local/bin/docker-entrypoint.sh  
  
# Expose ports  
EXPOSE 80 22  
  
# Set the entrypoint script  
ENTRYPOINT ["docker-entrypoint.sh"]  
  
# Set default command  
CMD ["php-fpm"]  
