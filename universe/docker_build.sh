#!/bin/bash
#
# Builds, tags and pushes a Docker image to a remote registry
# In this example, it's mine on Docker hub
#
# Usage
# docker_buid.sh <source directory> <tag>
#
# Example:
# docker_build.sh /Users/richard/code/dcos-openvpn 0.0.0-1.0

if [ $# -eq 0 ]; then
  echo "No arguments provided
Usage: docker_build.sh <path to Dockerfile directory> <image name> \
<repository name> <tag>
Example: docker_build.sh /code/dcos-openvpn dcos-openvpn aggress 0.0.0-1.0"
  exit 1
fi

cd "$1" || exit
docker build -t $2 .
docker tag $2 $3/$2:"$4"
docker push $3/$2:"$4"
