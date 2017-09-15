#!/bin/bash
#
# Builds a DC/OS local universe and pushes to a remote registry. Adds the
# new universe to Marathon and makes available in the DC/OS Catalog.
# Provides a cluster wide cleanup of the registry and all images for the
# new universe and one defined package.
#
# Prerequisites:
# 1. A local Docker daemon
# 2. A Remote docker registry
#   $ docker run -d -p 10000:5000 --restart=always --name registry registry:2
# 3. Docker daemon on each DC/OS node configured to work with insecure registry
#   https://docs.docker.com/registry/insecure/ or secure your registry
# 4. Define the remote registry as registry:registry_port
#
# Usage:
# local_universe.sh build
# local_universe.sh remove openvpn

registry="192.168.33.13"
registry_port="10000"
c_path="/Users/richard/code"
u_path="$c_path/universe"
ssh_config="$c_path/mesosphere-dcos-vagrant-ansible/ssh-config"
package=$2

function new {
  rm -rf $u_path
  cd $c_path || exit
  git clone https://github.com/mesosphere/universe --branch=version-3.x
  cd universe || exit
} 

function build {
  cd $u_path || exit
  scripts/build.sh
  ssh -F $ssh_config public-agent -C "sudo docker run -d -p 10000:5000 \
    --restart=always --name registry registry:2"
  DOCKER_IMAGE="$registry:$registry_port/universe-server" \
    DOCKER_TAG="universe-server" docker/server/build.bash
  DOCKER_IMAGE="$registry:$registry_port/universe-server" \
    DOCKER_TAG="universe-server" docker/server/build.bash publish
  dcos marathon app add $u_path/docker/server/target/marathon.json
  dcos package repo add \
    --index=0 universe-server http://universe.marathon.mesos:8085/repo
}

function remove {
  dcos package uninstall "$package"
  dcos marathon app remove /universe
  dcos package repo remove universe-server
  docker image rm -f $registry:$registry_port/universe-server:universe-server
  docker rmi -f $(docker images -aq)
  rm -f $u_path/target/*
  # Yuck, needs proper error handling. Sleeping whilst package container dies
  sleep 10
  ssh -F $ssh_config public-agent << 'EOF'
    sudo docker ps -f name=registry -aq | xargs docker kill
    sudo docker images | grep registry | awk {'print $3'} | xargs docker rmi -f
    sudo docker images | grep "$package" | awk {'print $3'} | xargs docker rmi -f
    sudo docker rm /registry
EOF
  ssh -F $ssh_config private-agent << 'EOF'
    sudo docker images | grep universe-server | awk {'print $3'} | xargs docker rmi -f
EOF
}

case "$1" in
  remove) remove ;;
  build)  build  ;;
  new)    new  ;;
  *)      echo "Usage: local_universe.sh build, remove <package>, new"; exit 1 ;;
esac