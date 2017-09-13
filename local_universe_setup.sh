#!/bin/bash
#
# Builds a DC/OS local universe and pushes to a remote registry. Adds the
# new universe to Marathon and makes available in the DC/OS Catalog
#
# Prerequisites:
# 1. A local Docker daemon
# 2. A Remote docker registry
#  $ docker run -d -p 10000:5000 --restart=always --name registry registry:2
# 3. Docker daemon on each DC/OS node configured to work with insecure registry
#   https://docs.docker.com/registry/insecure/ or secure your registry
# 4. Define the remote registry as REGISTRY:REGISTRY_PORT
#
# Usage:
# local_universe_setup.sh build




REGISTRY="192.168.33.13"
REGISTRY_PORT="10000"


function rebuild_universe {
  rm -rf /Users/richars/code/universe
  cd /Users/richard/code
  git clone https://github.com/mesosphere/universe --branch=version-3.x
  cd universe
} 

function build {
  echo "Building and pushing to $REGISTRY:$REGISTRY_PORT"
  cd /Users/richard/code/universe
  rm -f target/*
  docker rmi -f $(docker images -aq)
  scripts/build.sh
  DOCKER_IMAGE="$REGISTRY:$REGISTRY_PORT/universe-server" DOCKER_TAG="universe-server" docker/server/build.bash
  DOCKER_IMAGE="$REGISTRY:$REGISTRY_PORT/universe-server" DOCKER_TAG="universe-server" docker/server/build.bash publish
  dcos marathon app add /Users/richard/code/universe/docker/server/target/marathon.json
  dcos package repo add --index=0 universe-server http://universe.marathon.mesos:8085/repo
}

function remove {
  dcos package uninstall openvpn
  dcos marathon app remove /universe
  dcos package repo remove universe-server
  docker image rm -f $REGISTRY:$REGISTRY_PORT/universe-server:universe-server
  docker rmi -f $(docker images -aq)
}

case "$@" in
  remove) remove ;;
  build)  build  ;;
  rebuild_universe)  rebuild_universe  ;;
  *)      echo "build or remove";  exit 1 ;;
esac
