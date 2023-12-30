#!/bin/bash

function perform_backup() {
  database=$1
  password=$2

  echo "Performing backup for $database"

  # Dump the contents of the database to disk
  filename="$database.$current_date.sql"
  PGPASSWORD=$password pg_dump -h localhost -p 5432 -d $database -U postgres > $filename

  # Compress the contents
  compressed=$filename.gz
  gzip -c $filename > $compressed

  # Upload the data to S3
  s3_uri="s3://${backup_bucket}/$database/$compressed"
  aws s3 cp $compressed $s3_uri

  # Delete the temporary files
  rm $filename $compressed

  echo "Successfully dumped, compressed and uploaded (to $s3_uri) backup for '$database'"
}

# Download the Postgres password from S3
aws s3 cp s3://${configuration_bucket}/postgres/password /root
password=`cat /root/password`

# Get the current date
current_date=$(date +"%Y-%m-%dT%H:%M:%S")
echo "Performing backups for $current_date"

# Export the list of databases
database_list="/tmp/databases.csv"
sudo -u postgres psql -c "COPY (SELECT datname FROM pg_database WHERE datname NOT IN ('postgres', 'template0', 'template1')) TO '$database_list' WITH CSV DELIMITER ','"

# Backup each one of them sequentially
while IFS= read -r database; do
  perform_backup $database $password
done < $database_list

# Delete the list of databases and the password
rm -f $database_list /root/password
