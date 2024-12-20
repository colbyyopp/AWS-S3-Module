variable "bucket_name" {
  description = "Name of the bucket being created"
  type        = string
}

variable "enable_s3_encryption" {
  description = "Enable/disable S3 bucket encryption. Should only be set to disabled in rare instances (control tower)"
  type        = bool
  default     = true
}

variable "add_policy" {
  description = "Attaches policy made in the policy module to the bucket"
  type        = string
}

variable "cmk_id" {
  description = "ID of the customer managed key from the KMS module"
  type        = string
}

variable "rule" {
  description = "rules for the lifecycle configuration"
  # type        = map(any)
  default     = {}
}

variable "object_ownership" {
  description = "dictates who owns objects written into buckets"
  type        = string
}

variable "object" {
  description = "To create prefixes or keys"
  default     = {}
}

variable "object_lock" {
  description = "Will enable object lock on bucket. Requires versioning to be enabled"
  default     = {}
}

variable "versioning" {
  description = "Enable bucket versioning"
  type        = string
  default     = "Disabled"

  validation {
    condition     = var.versioning == "Disabled" || var.versioning == "Enabled" || var.versioning == "Suspended"
    error_message = "var.versioning can ONLY be set to 'Disabled', 'Enabled', or 'Suspended'"
  }
}