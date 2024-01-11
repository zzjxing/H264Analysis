#!/bin/bash
set -ex

if [ $# -lt 2 ]; then
    echo "docker.sh  <IMAGE_NAME> <DOCKER_NAME> "
    exit 1
fi
IMAGE_NAME=$1
DOCKER_NAME=$2
PROJECT_NAME=$(basename "$(pwd)")
PROJECT_DIR=$(realpath "$(pwd)")

if docker images | grep -q $IMAGE_NAME;then
  echo "Docker image $IMAGE_NAME already exists. Skipping build."
else
  DOCKER_FILE="$PROJECT_DIR/Dockerfile"
   if [ -e $DOCKER_FILE ]; then
    rm $DOCKER_FILE
  fi
  echo "FROM ubuntu:18.04" >> $DOCKER_FILE
  echo "RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list" >> $DOCKER_FILE
  echo "RUN sed -i s@/security.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list" >> $DOCKER_FILE
  echo "RUN mkdir /$PROJECT_NAME" >> $DOCKER_FILE
  echo "WORKDIR /$PROJECT_NAME" >> $DOCKER_FILE
  echo "ENV TZ=Asia/Shanghai" >> $DOCKER_FILE
  echo "RUN apt-get update && apt-get install -y gcc && apt-get install -y wget" >> $DOCKER_FILE
  docker build -t $IMAGE_NAME $PROJECT_DIR
fi

# basic mounting
MOUNTS="-v /tmp/.X11-unix/:/tmp/.X11-unix/ --privileged -v /etc/timezone:/etc/timezone:ro"

# mount docker utility to make building image inside container possible
MOUNTS="-v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker $MOUNTS"

# mount Project and Home
MOUNTS="-v $HOME:$HOME -v $PROJECT_DIR:/$PROJECT_NAME:rw $MOUNTS"

CMD_LINE="/bin/bash"

OPTIONS="-it --net=host --ulimit core=-1 --security-opt seccomp=unconfined --detach-keys=ctrl-i,c"

DC=docker
if [ 'root' != `whoami` ];then
    DC="sudo docker"
fi

CMD="$DC run $OPTIONS $MOUNTS --name $DOCKER_NAME $IMAGE_NAME $CMD_LINE"
echo "$CMD"

$CMD
