#!/bin/sh

# Remove any old keys or certs

rm -f *.pem
rm -f *.json
rm -f dcos-ca.crt

curl -k -v $(dcos config show core.dcos_url)/ca/dcos-ca.crt -o dcos-ca.crt

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

# Create a private and public keypair for the service
dcos security org service-accounts keypair spark-private.pem spark-public.pem
# Create a new service account using the previously created key
dcos security org service-accounts create -p spark-public.pem -d "spark service account" spark
# Check the new service account
dcos security org service-accounts show spark
# Create a secret to hold the private key
dcos security secrets create-sa-secret --strict spark-private.pem spark spark/private-key
# ACLs
dcos security org users grant spark dcos:mesos:master:framework:role:spark-role create
dcos security org users grant spark dcos:mesos:master:reservation:role:spark-role create
dcos security org users grant spark dcos:mesos:master:volume:role:spark-role create  
dcos security org users grant spark dcos:mesos:master:reservation:principal:spark create
dcos security org users grant spark dcos:mesos:master:reservation:principal:spark delete
dcos security org users grant spark dcos:mesos:master:volume:principal:spark create
dcos security org users grant spark dcos:mesos:master:volume:principal:spark delete
dcos security org users grant spark dcos:mesos:master:task:user:root create

# Install the package using the options file 

dcos package install spark --options=spark-strict.json --yes
