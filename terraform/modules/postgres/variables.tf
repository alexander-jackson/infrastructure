variable "name" {
  type        = string
  description = "Unique name of the instance"
}

variable "instance" {
  type = object({
    type              = string
    ami               = string
    vpc_id            = string
    subnet_id         = string
    availability_zone = string
  })
  description = "Parameters for the underlying EC2 instance"
}

variable "configuration" {
  type = object({
    major_version        = string
    storage_size         = number
    backup_bucket        = string
    configuration_bucket = string
  })
  description = "Parameters for the underlying Postgres install"
}

variable "key_name" {
  type        = string
  description = "The name of the `aws_key_pair` to use for the instance access"
}

variable "elastic_ip" {
  type        = bool
  description = "Whether the instance should have an elastic IP associated with it"
}
