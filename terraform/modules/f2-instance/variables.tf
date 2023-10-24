variable "name" {
  type        = string
  description = "Unique name of the instance"
}

variable "tag" {
  type        = string
  description = "The tag of the Docker image to run for `f2`"
}

variable "vpc_id" {
  type        = string
  description = "The identifier of the VPC for the security groups"
}

variable "subnet_id" {
  type        = string
  description = "The identifier of the subnet to place the instance in"
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

variable "config_bucket" {
  type        = string
  description = "The name of the bucket to use for configuration"
}

variable "config_key" {
  type        = string
  description = "The key in the bucket to use for configuration"
}
