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
