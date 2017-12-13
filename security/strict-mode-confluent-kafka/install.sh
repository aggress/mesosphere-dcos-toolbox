#!/bin/sh

# Remove any old keys or certs

rm -f *.pem
rm -f *.json
rm -f dcos-ca.crt

# Obtain the ca.crt for the DC/OS cluster

curl -k -v $(dcos config show core.dcos_url)/ca/dcos-ca.crt -o dcos-ca.crt

# Create a private and public keypair for the service, in this case confluent-kafka

dcos security org service-accounts keypair confluent-kafka-private.pem confluent-kafka-public.pem

# Create a new service account using the previously created key

dcos security org service-accounts create -p confluent-kafka-public.pem -d "Confluent Kafka service account" confluent-kafka

# Check the new service account

dcos security org service-accounts show confluent-kafka

# Create a secret to hold the private key

dcos security secrets create-sa-secret --strict confluent-kafka-private.pem confluent-kafka confluent-kafka/private-key

# Create a JSON options file with the new service account and secret

tee confluent-kafka-single-broker-strict.json << EOF
{
  "service": {
    "name": "confluent-kafka",
    "service_account": "confluent-kafka",
    "service_account_secret": "confluent-kafka/private-key"
  },
  "brokers": {
    "cpus": 1,
    "mem": 3192,
    "disk": 5000,
    "disk_type": "ROOT",
    "disk_path": "kafka-broker-data",
    "count": 1,
    "port": 0,
    "kill_grace_period": 30,
    "heap": {
      "size": 2048
    }
  }
}
EOF

# Configure the permissions

curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:confluent-kafka-role \
-d '{"description":"Controls the ability of confluent-kafka-role to register as a framework with the Mesos master"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:confluent-kafka-role \
-d '{"description":"Controls the ability of confluent-kafka-role to reserve resources"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:confluent-kafka-role \
-d '{"description":"Controls the ability of confluent-kafka-role to access volumes"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:principal:confluent-kafka \
-d '{"description":"Controls the ability of confluent-kafka to reserve resources"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:principal:confluent-kafka \
-d '{"description":"Controls the ability of confluent-kafka to access volumes"}' \
-H 'Content-Type: application/json'

curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:confluent-kafka-role/users/confluent-kafka/create
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:confluent-kafka-role/users/confluent-kafka/create
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:confluent-kafka-role/users/confluent-kafka/create
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:task:user:nobody/users/confluent-kafka/create
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:principal:confluent-kafka/users/confluent-kafka/delete
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:principal:confluent-kafka/users/confluent-kafka/delete

# Install the package using the options file 

dcos package install confluent-kafka --options=confluent-kafka-single-broker-strict.json --yes

