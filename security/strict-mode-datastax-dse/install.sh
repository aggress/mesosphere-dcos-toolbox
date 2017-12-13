#!/bin/sh

# Remove any old keys or certs

rm -f *.pem
rm -f *.json
rm -f dcos-ca.crt

# Obtain the ca.crt for the DC/OS cluster

curl -k -v $(dcos config show core.dcos_url)/ca/dcos-ca.crt -o dcos-ca.crt

# Create a private and public keypair for the service, in this case datastax-dse

dcos security org service-accounts keypair datastax-dse-private.pem datastax-dse-public.pem

# Create a new service account using the previously created key

dcos security org service-accounts create -p datastax-dse-public.pem -d "Datastax DSE service account" datastax-dse

# Check the new service account

dcos security org service-accounts show datastax-dse

# Create a secret to hold the private key

dcos security secrets create-sa-secret --strict datastax-dse-private.pem datastax-dse datastax-dse/private-key

# Create a JSON options file with the new service account and secret

tee datastax-dse-single-node-strict.json << EOF
{
  "service": {
    "name": "datastax-dse",
    "service_account": "datastax-dse",
    "service_secret_name": "datastax-dse/private-key"
  },
  "dsenode": {
    "count": 1,
    "virtual_network": "dcos",
    "cpus": 1,
    "mem": 3192,
    "heap": 2048,
    "jvm_opts": "-XX:+UseG1GC -XX:G1RSetUpdatingPauseTimePercent=5 -XX:MaxGCPauseMillis=500",
    "agent_cpus": 0.5,
    "agent_mem": 500,
    "data_disk": 256,
    "log_disk": 128,
    "commit_log_disk": 128,
    "solr_disk": 128
  }
}
EOF

# Configure the permissions

curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:datastax-dse-role \
-d '{"description":"Controls the ability of datastax-dse-role to register as a framework with the Mesos master"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:datastax-dse-role \
-d '{"description":"Controls the ability of datastax-dse-role to reserve resources"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:datastax-dse-role \
-d '{"description":"Controls the ability of datastax-dse-role to access volumes"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:principal:datastax-dse \
-d '{"description":"Controls the ability of datastax-dse to reserve resources"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:principal:datastax-dse \
-d '{"description":"Controls the ability of datastax-dse to access volumes"}' \
-H 'Content-Type: application/json'

curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:datastax-dse-role/users/datastax-dse/create
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:datastax-dse-role/users/datastax-dse/create
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:datastax-dse-role/users/datastax-dse/create
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:task:user:nobody/users/datastax-dse/create
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:principal:datastax-dse/users/datastax-dse/delete
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:principal:datastax-dse/users/datastax-dse/delete

# Install the package using the options file 

dcos package install datastax-dse --options=datastax-dse-single-node-strict.json --yes

