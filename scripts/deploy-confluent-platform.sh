#!/usr/bin/env bash

# This file:
#
#  - Deploys Confluent Platform using the new beta packages with dedicated Zookeeper
#
#
# Usage:
#
#  ./deploy-cp install | uninstall

# Exit on error. Append "|| true" if you expect an error.
#set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
set -o xtrace

# Clear out existing options.json files
rm -f *.json

packages=("beta-confluent-kafka-zookeeper" "beta-confluent-kafka" "confluent-connect" "confluent-control-center")
ssh_user="core" # Change accordingly


function cp_uninstall () {
    for package in "${packages[@]}"
    do
        dcos package uninstall ${package} --yes
    done
    watch dcos service # Watch this until all packages removed, then ctrl+c
}


function build_zookeeper_json () {
tee beta-confluent-kafka-zookeeper.json << EOF
{
  "service": {
    "name": "beta-confluent-kafka-zookeeper"
  }
}
EOF
}


function build_cp_json () {
zk=$(dcos beta-confluent-kafka-zookeeper --name=beta-confluent-kafka-zookeeper endpoint clientport | jq -r .dns[] | paste -sd, -)

tee beta-confluent-kafka.json << EOF
{
  "service": {
    "name": "beta-confluent-kafka"
  },
  "kafka": {
    "kafka_zookeeper_uri": "${zk}",
    "auto_create_topics_enable": true,
    "delete_topic_enable": true,
    "confluent_support_metrics_enable": true
  }
}
EOF

tee confluent-connect.json << EOF
{
  "connect": {
    "name": "connect",
    "instances": 1,
    "cpus": 2,
    "mem": 1024,
    "heap": 768,
    "role": "*",
    "kafka-service": "beta-confluent-kafka",
    "zookeeper-connect": "${zk}",
    "schema-registry-service": "schema-registry"
  }
}
EOF

tee confluent-control-center.json << EOF
{
  "control-center": {
    "name": "confluent-control-center",
    "instances": 1,
    "cpus": 2,
    "mem": 4096,
    "role": "*",
    "kafka-service": "beta-confluent-kafka",
    "connect-service": "connect",
    "confluent-controlcenter-internal-topics-partitions": 3,
    "confluent-controlcenter-internal-topics-replication": 2,
    "confluent-monitoring-interceptor-topic-partitions": 3,
    "confluent-monitoring-interceptor-topic-replication": 2,
    "zookeeper-connect": "${zk}"
  }
}
EOF
}


function control_center () {
    c3_host=$(dcos marathon app show control-center | jq -r .tasks[0].host)
    echo ${c3_host}
    c3_port=$(dcos marathon app show control-center | jq -r .tasks[0].ports[0])
    echo   ${c3_port}
    master=$(dcos cluster list --attached | tail -1 |  awk {'print $4'} | sed 's~http[s]*://~~g') # Don't judge me.
    ssh -N -L 9021:${c3_host}:${c3_port} ${ssh_user}@${master}
    echo "Open your browser on 127.0.0.1:9021 to access Confluent Control Center"
}


function cp_install () {
    build_zookeeper_json
    for package in "${packages[@]}"
    do
        dcos package install ${package} --options=${package}.json --yes
        sleep 30; # Give the scheduler time to fire up and build a deployment plan

        if [[ ${package} == "beta-confluent-kafka-zookeeper" || ${package} == "beta-confluent-kafka" ]]
        then

            while [[ "$(dcos ${package} --name=${package} plan status deploy | head -n1 | grep -c -v COMPLETE)" -eq 1 ]]
            do
                sleep 5
                echo "Waiting for the installation of ${package} to complete..."
                dcos ${package} --name=${package} plan status deploy
            done

            if [[ ${package} == "beta-confluent-kafka-zookeeper" ]]
            then
              build_cp_json # One time run to add the zk endpoints to the other options.json files
            fi
        fi
    done
}

case "$@" in
  install)          cp_install ;;
  uninstall)        cp_uninstall  ;;
  build_zk_json)    build_zk_json ;;
  build_cp_json)    build_cp_json ;;
  control_center)   control_center ;;
  *) exit 1 ;;
esac

