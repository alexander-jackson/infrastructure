# Terraform

Definitions for any infrastructure required to run applications. Everything is
now managed by Terraform.

## Contents

`aws.tf` contains the definitions for everything in AWS. The `modules`
directory contains some custom components for definitions such as S3 buckets,
`f2` instances and PostgreSQL databases.

The project defines:

* The `f2` and PostgreSQL instances that operate projects
* VPC and subnet stacks for networking
* DNS records for various services
* User accounts for managing or viewing the applications
