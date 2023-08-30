#!/bin/bash

# Setup the Postgres repository
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/trusted.gpg.d/pgdg.asc &>/dev/null

# Update the packages and install Postgres on the right version
apt update
apt install -y postgresql-${major_version} postgresql-contrib-${major_version} unzip

# Update the listen address to expose the server publicly
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/${major_version}/main/postgresql.conf

# Update the HBA configuration
mv /etc/postgresql/${major_version}/main/pg_hba.conf /etc/postgresql/${major_version}/main/pg_hba.conf.bak
cat <<'EOF' > /etc/postgresql/${major_version}/main/pg_hba.conf
${hba_file}
EOF

# Restart Postgres to apply the new settings
systemctl restart postgresql

# Get the AWS CLI setup up
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Download the Postgres password from the bucket
aws s3 cp s3://${configuration_bucket}/postgres/password /root

# Update the root password
password=`cat /root/password`
sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$password';"

rm /root/password
