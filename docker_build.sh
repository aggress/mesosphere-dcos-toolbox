#!/bin/bash
#
# Builds, tags and pushes a Docker image to a remote registry
# In this example, it's mine on Docker hub
#
# Usage:
# docker_buid.sh <source directory> <tag>
#
# Example:
# docker_build.sh /Users/richard/code/dcos-openvpn 0.0.0-1.0

cd $1
docker build -t dcos-openvpn .
docker tag dcos-openvpn aggress/dcos-openvpn:$2
docker push aggress/dcos-openvpn:$2
