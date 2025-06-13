#!/usr/bin/env bash

# Usage: env AWS_ACCESS_KEY_ID=your_access_key_id AWS_SECRET_ACCESS_KEY=your_secret_access_key ./renew-certificates.sh <server_name> <domain1> <domain2> ...

set -euo pipefail

# Get the server name as the first argument
SERVER_NAME="$1"

# Get the email address as the second argument
EMAIL_ADDRESS="$2"

USERNAME="ubuntu"

# Concatenate the username and server name for SSH
SSH_TARGET="${USERNAME}@${SERVER_NAME}"

# Check if the server name is provided
if [ -z "$SERVER_NAME" ]; then
  echo "Usage: $0 <server_name>"
  exit 1
fi

# Get the domains to renew as the remaining arguments
shift
shift
DOMAINS=("$@")

# Check if any domains are provided
if [ ${#DOMAINS[@]} -eq 0 ]; then
  echo "No domains provided for renewal."
  exit 1
fi

# Create a directory to store the certificates
mkdir ./certs

# SSH into the server and make sure Certbot is installed
ssh "$SSH_TARGET" << 'EOF'
  sudo snap install --classic certbot
  sudo ln -s /snap/bin/certbot /usr/bin/certbot
  sudo snap set certbot trust-plugin-with-root=ok
  sudo snap install certbot-dns-route53
EOF

# For each domain, renew the certificate
for DOMAIN in "${DOMAINS[@]}"; do
  echo "Renewing certificate for '$DOMAIN' using server '$SERVER_NAME'"

  ssh "$SSH_TARGET" "sudo certbot certonly --dns-route53 -d $DOMAIN --non-interactive --agree-tos --email $EMAIL_ADDRESS"

  # Copy the renewed certificates to the home directory on the server
  ssh "$SSH_TARGET" "sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /home/$USERNAME/$DOMAIN-fullchain.pem"
  ssh "$SSH_TARGET" "sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem /home/$USERNAME/$DOMAIN-privkey.pem"

  # Alter the permissions of the private key to allow read access
  ssh "$SSH_TARGET" "sudo chmod 644 /home/$USERNAME/$DOMAIN-privkey.pem"

  # Copy the renewed certificate to the local machine
  scp "$SSH_TARGET:/home/$USERNAME/$DOMAIN-fullchain.pem" "./certs/$DOMAIN-fullchain.pem"
  scp "$SSH_TARGET:/home/$USERNAME/$DOMAIN-privkey.pem" "./certs/$DOMAIN-privkey.pem"

  # Remove the copied files from the server
  ssh "$SSH_TARGET" "rm /home/$USERNAME/$DOMAIN-fullchain.pem /home/$USERNAME/$DOMAIN-privkey.pem"

  # Copy the renewed certificates to S3
  aws s3 cp "./certs/$DOMAIN-fullchain.pem" "s3://configuration-68f6c7/f2/certificates/$DOMAIN/fullchain.pem"
  aws s3 cp "./certs/$DOMAIN-privkey.pem" "s3://configuration-68f6c7/f2/certificates/$DOMAIN/privkey.pem"

  # Display a success message in green
  echo -e "\033[0;32mSuccessfully renewed certificate for '$DOMAIN'\033[0m"
done

# Clean up the local certs directory
rm -rf ./certs
