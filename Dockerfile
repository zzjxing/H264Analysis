FROM ubuntu:18.04
RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN sed -i s@/security.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN mkdir /H264Analysis
WORKDIR /H264Analysis
ENV TZ=Asia/Shanghai
RUN apt-get update && apt-get install -y gcc && apt-get install -y wget
