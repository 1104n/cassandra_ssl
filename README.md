## Run the Script
- chmod +x cert.sh
- ./cert.sh

## CA Cert and required Certificate Generation
- openssl genrsa -out ca-key.pem 2048
- openssl req -new -x509 -key ca-key.pem -out ca-cert.pem -days 365
- openssl genrsa -out server-key.pem 2048
- openssl req -new -key server-key.pem -out server-req.pem
- openssl x509 -req -in server-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -days 365
- openssl x509 -in ca-cert.pem -outform PEM -out ca-cert.pem
- openssl x509 -in server-cert.pem -outform PEM -out server-cert.pem

## Keystore and Truststore Certificate Generation
- keytool -import -alias cassandraCA -file ca-cert.pem -keystore truststore.jks
- openssl pkcs12 -export -in server-cert.pem -inkey server-key.pem -out server.p12 -name cassandra
- keytool -importkeystore -srckeystore server.p12 -srcstoretype PKCS12 -destkeystore keystore.jks -deststoretype JKS

## Client Certificate Generation
- openssl genrsa -out client-key.pem 2048
- openssl req -new -key client-key.pem -out client-csr.pem
- openssl x509 -req -in client-csr.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out client-cert.pem -days 365

## Configuration For SSL
- Now mount the SSL dir which has certificates inside /etc/ssl/certs in cassandra container

- Copy And Edit the /etc/cassandra/cassandra.yaml 

- In cassandra.yaml file edit and like this 
  keystore and trustore should be the path of ssl cert
  password should be the password which you gave when creating ssl certificates

server_encryption_options:
  internode_encryption: all
  legacy_ssl_storage_port_enabled: false
  keystore: /etc/ssl/certs/cassandra.keystore
  keystore_password: cassandra
  require_client_auth: false
  truststore: /etc/ssl/certs/cassandra.truststore
  truststore_password: cassandra
  require_endpoint_verification: false
  protocol: TLS

client_encryption_options:
  enabled: true
  optional: false
  keystore: /etc/ssl/certs/cassandra.keystore
  keystore_password: cassandra
  require_client_auth: false
  truststore: /etc/ssl/certs/cassandra.truststore

## Creating Cqlshrc
Create a cqlshrc file and these lines which used for client connection 

[connection]
hostname = "Server Ip addrs"
port = 9042
[authentication]
username = cassandra
password = cassandra

[ssl]
version = TLSv1.2
certfile =  /etc/ssl/certs/test_CLIENT.cer.pem
validate = false
userkey = /etc/ssl/certs/test_CLIENT.key.pem
usercert = /etc/ssl/certs/test_CLIENT.cer.pem

## docker-compose
Update the docker-compose.yml 
Build image
- docker build -t 'imagename' .
- docker-compose up -d

## Connect with
- cqlsh --ssl -u cassandra -p cassandra

