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
    bucket     = string
    vector_tag = string
  })
  description = "Parameters for use in logging output"
}

variable "backups" {
  type = object({
    bucket = string
  })
  description = "Parameters for use in taking database backups"
}

variable "hackathon" {
  type = object({
    bucket = string
  })
  description = "Parameters for use in the hackathon"
}

variable "alerting" {
  type = object({
    topic_arn = string
  })
  description = "Parameters for use in alerting for outages"
}

variable "key_name" {
  type        = string
  description = "The name of the `aws_key_pair` to use for the instance access"
}

variable "hosted_zones" {
  type        = list(string)
  description = "The hosted zone identifiers for Let's Encrypt renewals"
}

variable "inbound_http_subnet_id" {
  type        = string
  description = "The subnet ID to allow inbound HTTP traffic from"
  default     = null
}

variable "extra_ebs_volume" {
  type = object({
    size_gb     = number
    device_name = string
    volume_type = optional(string, "gp3")
    encrypted   = optional(bool, true)
  })
  description = "Configuration for an additional EBS volume"
  default     = null
}
