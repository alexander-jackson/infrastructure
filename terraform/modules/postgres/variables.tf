variable "name" {
  type        = string
  description = "Unique name of the instance"
}

variable "major_version" {
  type        = string
  description = "The major version of Postgres to run on the instance"
}

variable "backup_bucket" {
  type        = string
  description = "The name of the backup bucket"
}

variable "configuration_bucket" {
  type        = string
  description = "The name of the configuration bucket"
}

variable "vpc_id" {
  type        = string
  description = "The identifier of the VPC for the security groups"
}

variable "subnet_id" {
  type        = string
  description = "The identifier of the subnet to place the instance in"
}

variable "availability_zone" {
  type        = string
  description = "The availability zone for the instance and storage volume"
}

variable "storage_size" {
  type        = number
  description = "The amount of storage to allocate for the instance in GB"
}

variable "ami" {
  type        = string
  description = "The ami to use for the instance"
}

variable "instance_type" {
  type        = string
  description = "The class/type to use for the instance"
}

variable "key_name" {
  type        = string
  description = "The name of the `aws_key_pair` to use for the instance access"
}

variable "permitted_access" {
  type        = list(string)
  description = "The security group identifiers that are allowed to access the instance"
  default     = []
}
