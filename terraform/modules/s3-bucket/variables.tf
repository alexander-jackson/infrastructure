variable "bucket_name" {
  type        = string
  description = "The name of the bucket to create"
}

variable "pending_deletion" {
  type        = bool
  description = "Whether the bucket is pending deletion and objects should be cleared out"
  default     = false
}
