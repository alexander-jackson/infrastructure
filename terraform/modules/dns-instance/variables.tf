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
  description = "Configuration for the underlying instance to use"
}

variable "logging" {
  type = object({
    bucket     = string
    vector_tag = string
  })
  description = "Parameters for use in logging output"
}

variable "key_name" {
  type        = string
  description = "The name of the `aws_key_pair` to use for the instance access"
}

variable "elastic_ip_allocation_id" {
  type        = string
  default     = null
  description = "Optional allocation ID of an existing Elastic IP to associate with the instance. If not provided, a new EIP will be created."
}
