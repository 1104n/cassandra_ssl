#!/bin/bash

KEY_STORE_PATH="$PWD/certs"
mkdir -p "$KEY_STORE_PATH"
KEY_STORE="$KEY_STORE_PATH/cassandra.keystore"
PKS_KEY_STORE="$KEY_STORE_PATH/cassandra.pks12.keystore"
TRUST_STORE="$KEY_STORE_PATH/cassandra.truststore"
PASSWORD="YOUR PASS"
CLUSTER_NAME= #Cert File Name
COMMON_NAME= #Represents the primary identifier for the entity"
ORG_UNIT= #Specifies the subdivision of the organization, such as a department or team"
ORGANIZATION= #The name of the organization to which the entity belongs
LOCALITY= #Indicates the city or locality where the organization is located
STATE= #The state or province where the organization is located.
COUNTRY= #The two-letter country code where the organization is based.
DOMAIN_COMP= #Specifies components of the domain name associated with the entity. In this case, "domain" (domain.com)
DOMAIN_COM= #Specifies components of the domain name associated with the entity. In this case, "com" represent the domain cloudurable.com
CLUSTER_PUBLIC_CERT="$KEY_STORE_PATH/CLUSTER_${CLUSTER_NAME}.cer"
CLIENT_PUBLIC_CERT="$KEY_STORE_PATH/CLIENT_${CLUSTER_NAME}.cer"

### Cluster key setup.
# Create the cluster key for cluster communication.
keytool -genkey -keyalg RSA -alias "${CLUSTER_NAME}_CLUSTER" -keystore "$KEY_STORE" -storepass "$PASSWORD" -keypass "$PASSWORD" \
-dname "CN=$COMMON_NAME $CLUSTER_NAME cluster, OU=$ORG_UNIT, O=$ORGANIZATION, L=$LOCALITY, ST=$STATE, C=$COUNTRY, DC=$DOMAIN_COMP, DC=$DOMAIN_COM" \
-validity 36500

# Create the public key for the cluster which is used to identify nodes.
keytool -export -alias "${CLUSTER_NAME}_CLUSTER" -file "$CLUSTER_PUBLIC_CERT" -keystore "$KEY_STORE" \
-storepass "$PASSWORD" -keypass "$PASSWORD" -noprompt

# Import the identity of the cluster public cluster key into the trust store so that nodes can identify each other.
keytool -import -v -trustcacerts -alias "${CLUSTER_NAME}_CLUSTER" -file "$CLUSTER_PUBLIC_CERT" -keystore "$TRUST_STORE" \
-storepass "$PASSWORD" -keypass "$PASSWORD" -noprompt


### Client key setup.
# Create the client key for CQL.
keytool -genkey -keyalg RSA -alias "${CLUSTER_NAME}_CLIENT" -keystore "$KEY_STORE" -storepass "$PASSWORD" -keypass "$PASSWORD" \
-dname "CN=$COMMON_NAME $CLUSTER_NAME client, OU=$ORG_UNIT, O=$ORGANIZATION, L=$LOCALITY, ST=$STATE, C=$COUNTRY, DC=$DOMAIN_COMP, DC=$DOMAIN_COM" \
-validity 36500

# Create the public key for the client to identify itself.
keytool -export -alias "${CLUSTER_NAME}_CLIENT" -file "$CLIENT_PUBLIC_CERT" -keystore "$KEY_STORE" \
-storepass "$PASSWORD" -keypass "$PASSWORD" -noprompt

# Import the identity of the client pub  key into the trust store so nodes can identify this client.
keytool -importcert -v -trustcacerts -alias "${CLUSTER_NAME}_CLIENT" -file "$CLIENT_PUBLIC_CERT" -keystore "$TRUST_STORE" \
-storepass "$PASSWORD" -keypass "$PASSWORD" -noprompt

keytool -importkeystore -srckeystore "$KEY_STORE" -destkeystore "$PKS_KEY_STORE" -deststoretype PKCS12 \
-srcstorepass "$PASSWORD" -deststorepass "$PASSWORD"

openssl pkcs12 -in "$PKS_KEY_STORE" -nokeys -out "${CLUSTER_NAME}_CLIENT.cer.pem" -passin pass:cassandra
openssl pkcs12 -in "$PKS_KEY_STORE" -nodes -nocerts -out "${CLUSTER_NAME}_CLIENT.key.pem" -passin pass:cassandra
