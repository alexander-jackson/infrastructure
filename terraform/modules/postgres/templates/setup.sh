#!/bin/bash

function install_postgres() {
  # Setup the Postgres repository
  sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/trusted.gpg.d/pgdg.asc &>/dev/null

  # Update the packages and install Postgres on the right version
  apt update
  apt install -y postgresql-${major_version} postgresql-contrib-${major_version}
}

function mount_ebs_volume() {
  # Create a new file system on the EBS volume and mount it
  mkfs -t xfs /dev/nvme1n1
  mkdir /data
  mount /dev/nvme1n1 /data

  # Allow the Postgres user to own it
  chown -R postgres /data
}

function repoint_postgres_data_directory() {
  # Stop Postgres and twiddle with the data directory
  systemctl stop postgresql

  rsync -av /var/lib/postgresql /data
  mv /var/lib/postgresql/${major_version}/main /var/lib/postgresql/${major_version}/main.bak
  sed -i "s/data_directory = .*/data_directory = '\/data\/postgresql\/${major_version}\/main'/g" /etc/postgresql/${major_version}/main/postgresql.conf

  systemctl start postgresql
}

function set_postgres_password() {
  # Get the AWS CLI setup up
  apt install -y unzip
  curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  ./aws/install

  # Download the Postgres password from the bucket
  aws s3 cp s3://${configuration_bucket}/postgres/password /root

  # Update the root password
  password=`cat /root/password`
  sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$password';"

  rm /root/password
}

function update_postgres_configuration() {
  # Update the listen address to expose the server publicly
  sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/${major_version}/main/postgresql.conf

  # Update the HBA configuration
  mv /etc/postgresql/${major_version}/main/pg_hba.conf /etc/postgresql/${major_version}/main/pg_hba.conf.bak
  cat <<'EOF' > /etc/postgresql/${major_version}/main/pg_hba.conf
${hba_file}
EOF

  # Restart Postgres to apply the new settings
  systemctl restart postgresql
}

function setup_automated_backups() {
  # Write the backup script out
  script_dir="/root/postgres"
  script_path="$script_dir/backup.sh"

  mkdir -p $script_dir

  cat <<'EOF' > $script_path
${backup_script}
EOF

  # Make it executable
  chmod +x $script_path

  # Get `cron` to run it overnight
  (crontab -l ; echo "0 1 * * * $script_path") | crontab -
}

function main() {
  install_postgres
  mount_ebs_volume
  repoint_postgres_data_directory
  set_postgres_password
  update_postgres_configuration
  setup_automated_backups
}

main
