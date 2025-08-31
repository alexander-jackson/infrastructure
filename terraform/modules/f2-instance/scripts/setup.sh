#!/bin/bash

# Update existing list of packages and install some basic ones
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common awscli

# Handle extra EBS volume if configured
if [ -n "${extra_volume_device}" ]; then
    echo "Looking for extra EBS volume (specified as ${extra_volume_device})"

    # On newer instance types, EBS volumes appear as NVMe devices
    # Find the first unpartitioned NVMe device that's not the root volume
    EBS_DEVICE=""
    for device in /dev/nvme*n1; do
        if [ -b "$device" ]; then
            # Check if this device has partitions (root device will have partitions)
            if ! lsblk "$device" | grep -q part; then
                # Check if it's not already mounted
                if ! mount | grep -q "$device"; then
                    EBS_DEVICE="$device"
                    echo "Found EBS volume at $EBS_DEVICE"
                    break
                fi
            fi
        fi
    done

    # Fallback to the originally specified device name
    if [ -z "$EBS_DEVICE" ] && [ -b "${extra_volume_device}" ]; then
        EBS_DEVICE="${extra_volume_device}"
        echo "Using originally specified device ${extra_volume_device}"
    fi

    if [ -n "$EBS_DEVICE" ]; then
        echo "Configuring extra EBS volume at $EBS_DEVICE"

        # Check if the device is already formatted
        if ! sudo blkid "$EBS_DEVICE"; then
            echo "Formatting $EBS_DEVICE with ext4 filesystem"
            sudo mkfs.ext4 -F "$EBS_DEVICE"
        else
            echo "Device $EBS_DEVICE is already formatted"
        fi

        # Create mount point and mount the volume directly to /mnt/data
        sudo mkdir -p /mnt/data
        sudo mount "$EBS_DEVICE" /mnt/data

        # Add to fstab for persistent mounting (use UUID for reliability)
        UUID=$(sudo blkid -s UUID -o value "$EBS_DEVICE")
        if [ -n "$UUID" ] && ! grep -q "$UUID" /etc/fstab; then
            echo "UUID=$UUID /mnt/data ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
        fi

        # Set appropriate permissions for the mount point
        sudo chown ubuntu:ubuntu /mnt/data
        sudo chmod 755 /mnt/data

        echo "Extra EBS volume configured and mounted directly at /mnt/data"
    else
        echo "Warning: No suitable EBS volume found"
    fi
fi

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

sudo docker network create --driver bridge internal
sudo docker run -d -v /var/run/docker.sock:/var/run/docker.sock -v /tmp:/tmp -v /mnt:/mnt --network internal -p 80:80 -p 443:443 alexanderjackson/f2:${tag} -- --config s3://${config_bucket}/${config_key}
