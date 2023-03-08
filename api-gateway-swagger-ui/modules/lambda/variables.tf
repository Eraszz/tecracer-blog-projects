################################################################################
# Variables
################################################################################

variable "function_name" {
  description = "Unique name for your Lambda Function."
  type        = string
}

variable "role" {
  description = "Amazon Resource Name (ARN) of the function's execution role. The role provides the function's identity and access to AWS services and resources."
  type        = string
}

variable "filename" {
  description = "Path to the function's deployment package within the local filesystem. Conflicts with image_uri, s3_bucket, s3_key, and s3_object_version."
  type        = string
  default     = null
}

variable "handler" {
  description = "Function entrypoint in your code."
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename or s3_key."
  type        = string
  default     = null
}

variable "publish" {
  description = "Whether to publish creation/change as new Lambda Function Version."
  type        = bool
  default     = false
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function."
  type        = list(string)
  default     = []
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime. Defaults to 128."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Amount of time your Lambda Function has to run in seconds."
  type        = number
  default     = 5
}

variable "runtime" {
  description = "Identifier of the function's runtime."
  type        = string
  default     = "python3.9"
}

variable "permission" {
  description = "Map of Lambda Permissions to create"
  type        = object({
    action        = string
    principal     = string
    qualifier     = string
    source_arn    = string
  })
}

variable "alias" {
  description = "Map of Lambda Aliases to create"
  type        = object({
    name             = string
    function_version = string
  })
}
