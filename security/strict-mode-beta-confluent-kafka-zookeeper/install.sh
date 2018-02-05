#!/usr/bin/env bash

# Author: Richard Shaw - rshaw@mesosphere.com
#
# Description:
#
#  - Deploys beta-confluent-kafka-zookeeper in strict mode
#
# Usage:
#
#  ./deploy-beta-confluent-kafka-zookeeper-strict.sh

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

# Remove any old keys or certs

rm -f *.pem
rm -f *.json
rm -f dcos-ca.crt

#dcos package install dcos-enterprise-cli --yes

# Get the dcos_url
dcos_url=$(dcos config show core.dcos_url)

# Get the token just the once
dcos_token=$(dcos config show core.dcos_acs_token)

# Get the ca.crt for the DC/OS cluster
curl -k -s ${dcos_url}/ca/dcos-ca.crt -o dcos-ca.crt


# Create a private and public keypair for the service, in this case beta-confluent-kafka-zookeeper
dcos security org service-accounts keypair beta-confluent-kafka-zookeeper-private.pem beta-confluent-kafka-zookeeper-public.pem

# Create a new service account using the previously created key
dcos security org service-accounts create -p beta-confluent-kafka-zookeeper-public.pem -d "beta-confluent-kafka-zookeeper service account" beta-confluent-kafka-zookeeper

# Check the new service account
dcos security org service-accounts show beta-confluent-kafka-zookeeper

# Create a secret to hold the private key
dcos security secrets create-sa-secret --strict beta-confluent-kafka-zookeeper-private.pem beta-confluent-kafka-zookeeper beta-confluent-kafka-zookeeper/private-key


# ACLs
dcos security org users grant beta-confluent-kafka-zookeeper dcos:mesos:master:framework:role:beta-confluent-kafka-zookeeper-role create
dcos security org users grant beta-confluent-kafka-zookeeper dcos:mesos:master:reservation:role:beta-confluent-kafka-zookeeper-role create
dcos security org users grant beta-confluent-kafka-zookeeper dcos:mesos:master:volume:role:beta-confluent-kafka-zookeeper-role create  
dcos security org users grant beta-confluent-kafka-zookeeper dcos:mesos:master:reservation:principal:beta-confluent-kafka-zookeeper create
dcos security org users grant beta-confluent-kafka-zookeeper dcos:mesos:master:reservation:principal:beta-confluent-kafka-zookeeper delete
dcos security org users grant beta-confluent-kafka-zookeeper dcos:mesos:master:volume:principal:beta-confluent-kafka-zookeeper create
dcos security org users grant beta-confluent-kafka-zookeeper dcos:mesos:master:volume:principal:beta-confluent-kafka-zookeeper delete
dcos security org users grant beta-confluent-kafka-zookeeper dcos:mesos:master:task:user:nobody create


# Create a JSON options file with the new service account and secret
tee beta-confluent-kafka-zookeeper-strict.json << EOF
{
  "service": {
    "name": "beta-confluent-kafka-zookeeper",
    "service_account": "beta-confluent-kafka-zookeeper",
    "service_account_secret": "beta-confluent-kafka-zookeeper/private-key"
  }
}
EOF

# Install the package using the options file 
dcos package install beta-confluent-kafka-zookeeper --options=beta-confluent-kafka-zookeeper-strict.json --yes
