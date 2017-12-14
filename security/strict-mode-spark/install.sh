#!/bin/sh

# Remove any old keys or certs

rm -f *.pem
rm -f *.json
rm -f dcos-ca.crt

# Obtain the ca.crt for the DC/OS cluster

curl -k -v $(dcos config show core.dcos_url)/ca/dcos-ca.crt -o dcos-ca.crt

# Create a private and public keypair for the service, in this case spark

dcos security org service-accounts keypair spark-private.pem spark-public.pem

# Create a new service account using the previously created key

dcos security org service-accounts create -p spark-public.pem -d "Spark service account" spark

# Check the new service account

dcos security org service-accounts show spark

# Create a secret to hold the private key

dcos security secrets create-sa-secret --strict spark-private.pem spark spark/private-key

# Create a JSON options file with the new service account and secret

tee spark-strict.json << EOF
{
  "service": {
    "name": "spark",
    "cpus": 1,
    "mem": 1024,
    "role": "*",
    "service_account": "spark",
    "service_account_secret": "spark/private-key",
    "user": "root"
  }
}
EOF

# Configure the permissions

curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:task:user:nobody \
-d '{"description":"Allows Linux user nobody to execute tasks"}' \
-H 'Content-Type: application/json'
curl -X PUT --cacert dcos-ca.crt \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:* \
-d '{"description":"Allows a framework to register with the Mesos master using the Mesos default role"}' \
-H 'Content-Type: application/json'
curl -X PUT -k \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" "$(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:task:app_id:%252Fspark" \
-d '{"description":"Allow to read the task state"}' \
-H 'Content-Type: application/json'

curl -X PUT -k \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" "$(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:*/users/spark/create"
curl -X PUT -k \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" "$(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:task:app_id:%252Fspark/users/spark/create"
curl -X PUT -k \
-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:task:user:nobody/users/spark/create

# Install the package using the options file 

dcos package install spark --options=spark-strict.json --yes

