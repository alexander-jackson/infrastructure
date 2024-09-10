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

# Download the `vector` configuration and get it running
aws s3 cp s3://configuration-68f6c7/vector/vector.yaml /home/ubuntu/vector.yaml
sudo docker run -d -v /var/run/docker.sock:/var/run/docker.sock -v /home/ubuntu/vector.yaml:/etc/vector/vector.yaml timberio/vector:${vector_tag}

# Allow the `ubuntu` user to run `docker` commands (for SSH access)
sudo usermod -aG docker ubuntu

sudo docker run -d -v /var/run/docker.sock:/var/run/docker.sock -p 443:443 alexanderjackson/f2:${tag} -- --config s3://${config_bucket}/${config_key}
