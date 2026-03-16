# 基础镜像
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NVM_DIR="/root/.nvm"
ENV TZ=Asia/Shanghai
ENV SSH_USER=ubuntu

# 解决 Kaniko apt sandbox 问题
RUN echo 'APT::Sandbox::User "root";' > /etc/apt/apt.conf.d/no-sandbox

COPY entrypoint.sh /entrypoint.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY reboot.sh /usr/local/sbin/reboot
COPY index.js /index.js
COPY app.js /app.js
COPY package.json /package.json
COPY app.py /app.py
COPY app.sh /app.sh
COPY requirements.txt /requirements.txt
COPY agent /agent
COPY start.sh /start.sh
COPY index.html /var/www/html/index.html

# ===============================
# 安装基础软件 + Apache + PHP
# ===============================
RUN apt-get update && \
    apt-get install -y \
    tzdata \
    openssh-server \
    sudo \
    curl \
    ca-certificates \
    wget \
    vim \
    net-tools \
    supervisor \
    cron \
    unzip \
    iputils-ping \
    telnet \
    git \
    iproute2 \
    nano \
    python3 \
    python3-pip \
    apache2 \
    php \
    libapache2-mod-php \
    php-cli \
    php-curl \
    php-mysql \
    php-xml \
    php-mbstring \
    php-zip \
    php-gd \
    php-intl \
    php-bcmath \
    --no-install-recommends && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ===============================
# Python 依赖
# ===============================
RUN pip3 install --no-cache-dir -r /requirements.txt

# ===============================
# Node 环境
# ===============================
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install 24.13.0 && \
    nvm alias default 24.13.0 && \
    node -v && npm -v && \
    npm install

ENV PATH="$NVM_DIR/versions/node/v24.13.0/bin:$PATH"

# ===============================
# Apache 配置
# ===============================
RUN a2enmod php && \
    a2enmod rewrite && \
    mkdir -p /var/run/sshd && \
    chmod +x /entrypoint.sh && \
    chmod +x /usr/local/sbin/reboot && \
    chmod +x /index.js && \
    chmod +x /app.py && \
    chmod +x /app.js && \
    chmod +x /app.sh && \
    chmod +x /agent && \
    chmod +x /start.sh && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# ===============================
# 端口
# ===============================
EXPOSE 22
EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/bin/supervisord","-n","-c","/etc/supervisor/supervisord.conf"]
