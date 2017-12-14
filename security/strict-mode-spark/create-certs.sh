#!/bin/bash

set -o nounset \
    -o errexit \
    -o verbose \
    -o xtrace

# Generate CA key
openssl req -new -x509 -keyout snakeoil-ca-1.key -out snakeoil-ca-1.crt -days 365 -subj '/CN=ca1.test.example.com/OU=TEST/O=MESOSPHERE/L=SF/S=Ca/C=US' -passin pass:secret -passout pass:secret

openssl genrsa -des3 -passout "pass:secret" -out spark.client.key 1024
openssl req -passin "pass:secret" -passout "pass:secret" -key spark.client.key -new -out spark.client.req -subj '/CN=spark.test.example.com/OU=TEST/O=MESOSPHERE/L=SF/S=Ca/C=US'
openssl x509 -req -CA snakeoil-ca-1.crt -CAkey snakeoil-ca-1.key -in spark.client.req -out spark-ca1-signed.pem -days 9999 -CAcreateserial -passin "pass:secret"

keytool -genkey -noprompt \
 -alias spark \
 -dname "CN=spark.test.example.com, OU=TEST, O=MESOSPHERE, L=SF, S=Ca, C=US" \
 -keystore spark.keystore.jks \
 -keyalg RSA \
 -storepass secret \
 -keypass secret

# Create CSR, sign the key and import back into keystore
keytool -noprompt -keystore spark.keystore.jks -alias spark -certreq -file spark.csr -storepass secret -keypass secret

openssl x509 -req -CA snakeoil-ca-1.crt -CAkey snakeoil-ca-1.key -in spark.csr -out spark-ca1-signed.crt -days 9999 -CAcreateserial -passin pass:secret

keytool -noprompt -keystore spark.keystore.jks -alias CARoot -import -file snakeoil-ca-1.crt -storepass secret -keypass secret

keytool -noprompt -keystore spark.keystore.jks -alias spark -import -file spark-ca1-signed.crt -storepass secret -keypass secret

# Create truststore and import the CA cert.
keytool -noprompt -keystore spark.truststore.jks -alias CARoot -import -file snakeoil-ca-1.crt -storepass secret -keypass secret

echo "secret" > spark_sslkey_creds
echo "secret" > spark_keystore_creds
echo "secret" > spark_truststore_creds
