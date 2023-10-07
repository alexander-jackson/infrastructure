variable "bucket_name" {
  type        = string
  description = "The name of the bucket to create"
}

variable "with_random_id" {
  type        = bool
  description = "Whether to use a `random_id` resource"
  default     = false
}
