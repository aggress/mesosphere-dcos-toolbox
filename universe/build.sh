#!/usr/bin/env bash
# This file:
#
#  - Builds a DC/OS Local Universe
#
# Usage:
#
#  ./build.sh

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
# set -o xtrace


## Variables 

__build_path="universe/docker/local-universe"

function __main () {
  cd /tmp/
  git clone https://github.com/mesosphere/universe.git --branch version-3.x && \
  cd ${__build_path}
  make base
  make DCOS_VERSION=${DCOS_VER} DCOS_PACKAGE_INCLUDE=${PACKAGES} local-universe
  cp /tmp/${__build_path}/local-universe.tar.gz /tmp/build/
  cp /tmp/${__build_path}/dcos-local-universe-registry.service /tmp/build/
  cp /tmp/${__build_path}/dcos-local-universe-http.service /tmp/build/
  exit 1
}

__main

