#!/bin/sh

# Remove any old keys or certs

rm -f *.pem
rm -f *.json
rm -f dcos-ca.crt

# Obtain the ca.crt for the DC/OS cluster

curl -k -v $(dcos config show core.dcos_url)/ca/dcos-ca.crt -o dcos-ca.crt

# Create a private and public keypair for the service, in this case kafka

dcos security org service-accounts keypair kafka-private.pem kafka-public.pem

# Create a new service account using the previously created key

dcos security org service-accounts create -p kafka-public.pem -d "Kafka service account" kafka

# Check the new service account

dcos security org service-accounts show kafka

# Create a secret to hold the private key

dcos security secrets create-sa-secret --strict kafka-private.pem kafka kafka/private-key

# Create a JSON options file with the new service account and secret

tee kafka-single-broker-strict.json << EOF
{
  "service": {
    "name": "kafka",
    "service_account": "kafka",
    "service_account_secret": "kafka/private-key"
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
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:kafka-role \
-d '{"description":"Controls the ability of kafka-role to register as a framework with the Mesos master"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:kafka-role \
-d '{"description":"Controls the ability of kafka-role to reserve resources"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:kafka-role \
-d '{"description":"Controls the ability of kafka-role to access volumes"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:principal:kafka \
-d '{"description":"Controls the ability of kafka to reserve resources"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:principal:kafka \
-d '{"description":"Controls the ability of kafka to access volumes"}' \
-H 'Content-Type: application/json'

curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:kafka-role/users/kafka/create
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:kafka-role/users/kafka/create
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:kafka-role/users/kafka/create
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:task:user:nobody/users/kafka/create
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:principal:kafka/users/kafka/delete
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:principal:kafka/users/kafka/delete

# Install the package using the options file 

dcos package install kafka --options=kafka-single-broker-strict.json --yes

