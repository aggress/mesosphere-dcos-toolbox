#!/bin/sh

# Remove any old keys or certs

rm -f *.pem
rm -f *.json
rm -f dcos-ca.crt

# Obtain the ca.crt for the DC/OS cluster

curl -k -v $(dcos config show core.dcos_url)/ca/dcos-ca.crt -o dcos-ca.crt

# Create a private and public keypair for the service, in this case cassandra

dcos security org service-accounts keypair cassandra-private.pem cassandra-public.pem

# Create a new service account using the previously created key

dcos security org service-accounts create -p cassandra-public.pem -d "Cassandra service account" cassandra

# Check the new service account

dcos security org service-accounts show cassandra

# Create a secret to hold the private key

dcos security secrets create-sa-secret --strict cassandra-private.pem cassandra cassandra/private-key

# Create a JSON options file with the new service account and secret

tee cassandra-single-node-strict.json << EOF
{
  "service": {
    "name": "cassandra",
    "service_account_secret": "cassandra/private-key",
    "service_account": "cassandra"
  },
  "nodes": {
    "count": 3,
    "cpus": 0.5,
    "mem": 3192,
    "disk": 1024
  }
}
EOF

# Configure the permissions

curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:cassandra-role \
-d '{"description":"Controls the ability of cassandra-role to register as a framework with the Mesos master"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:cassandra-role \
-d '{"description":"Controls the ability of cassandra-role to reserve resources"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:cassandra-role \
-d '{"description":"Controls the ability of cassandra-role to access volumes"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:principal:cassandra \
-d '{"description":"Controls the ability of cassandra to reserve resources"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:principal:cassandra \
-d '{"description":"Controls the ability of cassandra to access volumes"}' \
-H 'Content-Type: application/json'

curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:cassandra-role/users/cassandra/create
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:cassandra-role/users/cassandra/create
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:cassandra-role/users/cassandra/create
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:task:user:nobody/users/cassandra/create
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:principal:cassandra/users/cassandra/delete
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:principal:cassandra/users/cassandra/delete

# Install the package using the options file 

dcos package install cassandra --options=cassandra-single-node-strict.json --yes

