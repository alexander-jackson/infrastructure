#!/bin/bash

# Update existing list of packages and install some basic ones
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common awscli

# Set up the Docker registry
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package list and install Docker
sudo apt update
sudo apt install -y docker-ce

# Allow the `ubuntu` user to run `docker` commands (for SSH access)
sudo usermod -aG docker ubuntu

# Authenticate with ECR for pulling images
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${account_id}.dkr.ecr.${region}.amazonaws.com

sudo docker run -d -v /var/run/docker.sock:/var/run/docker.sock -p 443:443 alexanderjackson/f2:${tag} -- --config s3://${config_bucket}/${config_key}
