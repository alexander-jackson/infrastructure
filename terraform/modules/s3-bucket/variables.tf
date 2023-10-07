variable "bucket_name" {
  type        = string
  description = "The name of the bucket to create"
}

variable "with_random_id" {
  type        = bool
  description = "Whether to use a `random_id` resource"
  default     = false
}

variable "pending_deletion" {
  type        = bool
  description = "Whether the bucket is pending deletion and objects should be cleared out"
  default     = false
}
