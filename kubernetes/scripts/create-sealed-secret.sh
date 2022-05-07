#!/usr/bin/env bash

# Sample usage: ./create-sealed-secret.sh <public_certificate> <name> <key_value_pair>

cert=$1
name=$2
key_value_pair=$3

# Create the secret itself

kubectl create secret generic $name --from-literal=$key_value_pair --dry-run=client -o yaml > ${name}.yaml

# Encrypt it using `kubeseal`

kubeseal --cert $cert -o yaml <${name}.yaml >sealed-${name}.yaml

# Delete the unencrypted version

rm ${name}.yaml
