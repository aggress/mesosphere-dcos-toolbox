#!/usr/bin/env bash
# This file:
#
#  - Runs the build process 
#
# Usage:
#
#  ./run.sh

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

docker run --name=builder -v /var/run/docker.sock:/var/run/docker.sock \
-v /tmp/dcos-local-universe:/tmp/build --env-file=local_universe.txt \
aggress/dcos-local-universe-builder:latest