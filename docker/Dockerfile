FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    LC_ALL='en_US.UTF-8' \
    USER=root \
    PASSWD=passwd

# 换源
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

# 安装ssh服务
RUN apt-get update \
    && apt-get install -y openssh-server \
    && echo "PermitRootLogin yes" >>  /etc/ssh/sshd_config \
    && echo "port 22" >> /etc/ssh/sshd_config \
    && /etc/init.d/ssh start

# 安装常用工具 配置字体
RUN apt-get install -y \
    screen vim curl zip unzip wget htop net-tools inetutils-ping \
    locales \
    ttf-wqy-zenhei \
    && locale-gen en_US.UTF-8

# 安装vncserver
RUN apt-get install -y tightvncserver

# vnc密码
run (echo "$PASSWD"; echo "$PASSWD"; echo "n") | vncpasswd

# 安装bochs及开发工具
RUN apt-get install -y \
    make \
    build-essential \
    xorg-dev \
    bison \
    gcc \
    g++ \
    gdb \
    nasm \
    git

RUN cd /root \
    && wget -O bochs-2.7.tar.gz https://sourceforge.net/projects/bochs/files/bochs/2.7/bochs-2.7.tar.gz/download \
    && tar -xvf bochs-2.7.tar.gz \
    && cd bochs-2.7 \
    && ./configure --enable-gdb-stub \
    && make \
    && make install \
    && ./configure --enable-debugger --enable-disasm \
    && make \
    && cp bochs /usr/local/bin/bochs-dbg \
    && cd .. \
    && rm -rf bochs-2.7 bochs-2.7.tar.gz

# 清除apt缓存
RUN apt-get autoclean && rm -rf /var/lib/apt/lists/*

# 修改root用户密码
RUN echo "$USER:$PASSWD" | chpasswd

# bashrc
RUN cp /etc/skel/.bash_logout /root/ \
    && cp /etc/skel/.bashrc /root/ \
    && cp /etc/skel/.profile /root/

# 创建容器启动时的脚本，脚本内容包括服务的开启，其中tail -f /dev/null为阻塞命令，保证容器运行时不会执行完毕并直接退出
RUN touch start.sh \
    && echo "#!/bin/bash" >> start.sh \
    && echo "" >> start.sh \
    && echo "vncserver -kill :1 &> /dev/null" >> start.sh \
    && echo "rm -f /tmp/.X1-lock" >> start.sh \
    && echo "rm -f /tmp/.X11-unix/X1" >> start.sh \
    && echo "vncserver -geometry 1280x720 :1 &> /dev/null" >> start.sh \
    && echo "/etc/init.d/ssh start && tail -f /dev/null" >> start.sh \
    && chmod 777 start.sh

EXPOSE 22 5901

# 启动脚本start.sh
CMD ["./start.sh"]
