#!/usr/bin/env bash

function generate_client_cert() {
	client_name=$1
	common_name=$2

	# Generate a key, CSR and certificate for the client
	openssl genrsa -out $client_name.key 2048
	openssl req -new -key $client_name.key -subj "/C=GB/ST=England/L=London/O=client/CN=$common_name" -addext "subjectAltName = DNS:localhost" -out $client_name.csr
	openssl x509 -req -in $client_name.csr -CA ca.crt -CAkey ca.key -CAcreateserial -extfile <(printf "subjectAltName=DNS:localhost") -days 365 -out $client_name.crt

	# Generate a PEM file for `curl` and a `p12` for browser usage
	cat $client_name.crt $client_name.key > $client_name.pem
	/usr/bin/openssl pkcs12 -export -in $client_name.pem -out $client_name.p12 -name "$client_name"
}

# Remove existing certificates
rm -r certs

# Create the directory again
mkdir certs
cd certs

# Generate a key for the CA as well as a self-signed certificate
openssl genrsa -out ca.key 2048
openssl req -new -x509 -key ca.key -out ca.crt -subj "/C=GB/ST=England/L=London/O=root/CN=localhost"

# Generate a key, CSR and certificate for the server
openssl genrsa -out localhost.key 2048
openssl req -new -key localhost.key -subj "/C=GB/ST=England/L=London/O=server/CN=localhost" -addext "subjectAltName = DNS:localhost" -out localhost.csr
openssl x509 -req -in localhost.csr -CA ca.crt -CAkey ca.key -CAcreateserial -extfile <(printf "subjectAltName=DNS:localhost") -out localhost.crt

# Concatenate the certificates for the server to use
cat localhost.crt ca.crt > localhost.bundle.crt

# Generate client certificates
generate_client_cert mobile "Pixel 6"
generate_client_cert work "M1 Max"
generate_client_cert personal "M2 Pro"

cd ..
