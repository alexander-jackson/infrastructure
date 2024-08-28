variable "name" {
  type        = string
  description = "Unique name of the instance"
}

variable "instance" {
  type = object({
    ami       = string
    vpc_id    = string
    subnet_id = string
    type      = string
  })
  description = "Parameters for the underlying EC2 instance"
}

variable "configuration" {
  type = object({
    bucket    = string
    key       = string
    image_tag = string
  })
  description = "Parameters for the underlying `f2` instance to use"
}

variable "logging" {
  type = object({
    bucket = string
  })
  description = "Parameters for use in logging output"
}

variable "key_name" {
  type        = string
  description = "The name of the `aws_key_pair` to use for the instance access"
}

variable "hosted_zone_id" {
  type        = string
  description = "The hosted zone identifier for Let's Encrypt renewals"
}
