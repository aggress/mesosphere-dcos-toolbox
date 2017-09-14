#!/bin/bash
#
# Builds a DC/OS local universe and pushes to a remote registry. Adds the
# new universe to Marathon and makes available in the DC/OS Catalog
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
u_path="/Users/richard/code/universe"
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
  docker_image="$registry:$registry_port/universe-server" \
    docker_tag="universe-server" docker/server/build.bash
  docker_image="$registry:$registry_port/universe-server" \
    docker_tag="universe-server" docker/server/build.bash publish
  dcos marathon app add $u_path/docker/server/target/marathon.json
  dcos package repo add \
    --index=0 universe-server http://universe.marathon.mesos:8085/repo
}

function remove {
  dcos package uninstall "$package"
  dcos marathon app remove /universe
  dcos package repo remove universe-server
  docker image rm -f $registry:$registry_port/universe-server:universe-server
  docker rmi -f "$(docker images -aq)"
  rm -f $u_path/target/*
}

case "$1" in
  remove) remove ;;
  build)  build  ;;
  new)    new  ;;
  *)      echo "build, remove <package>, new"; exit 1 ;;
esac