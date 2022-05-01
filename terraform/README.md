# Terraform

Everything about the server is managed by Terraform, including the project,
droplet that things are running on and the DNS records that point to it.

## Contents

`main.tf` currently stores definitions for:

* The Digital Ocean project everything is managed under
* The server instance itself
* The top level DNS entry `blackboards.pl`
* The DNS records for individual services, such as `blackboards` at the root
