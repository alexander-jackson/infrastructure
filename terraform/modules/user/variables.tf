variable "name" {
  type        = string
  description = "The name of the user (ie. user.name)"
}

variable "key" {
  type        = string
  description = "The PGP key to use for their account access"
}

variable "hackathon_bucket_name" {
  type        = string
  description = "The name of the bucket being used in the hackathon"
}

variable "forkup_dev_role_arn" {
  type        = string
  description = "The ARN of the forkup-dev role"
}
