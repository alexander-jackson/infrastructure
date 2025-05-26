#!/usr/bin/env bash
# This script decrypts a file using GPG and outputs the decrypted content to stdout.

export GPG_TTY=$(tty)
input="$1"
output="$2"

# Check both arguments are provided and the encrypted file exists
if [ -z "$input" ] || [ -z "$output" ]; then
  echo "Usage: $0 <encrypted_file> <decrypted_file>"
  exit 1
fi

if [ ! -f "$input" ]; then
  echo "File not found: $input"
  exit 1
fi

# Decrypt the file using GPG
base64 --decode --input "$input" | gpg --decrypt --output "$output"
