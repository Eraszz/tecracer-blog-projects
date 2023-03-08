################################################################################
# Variables
################################################################################

variable "name" {
  description = "Name of the security group"
  type        = string
}

variable "principal" {
  description = "Use the Principal element in a resource-based JSON policy to specify the principal that is allowed or denied access to a resource."
  type        = map(list(string))
  default     = {}
}

variable "actions" {
  description = "List of actions to be used within the IAM role trust policy"
  type        = list(string)
  default     = ["sts:AssumeRole"]
}

variable "conditions" {
  description = "List of conditions to be used within the IAM role trust policy"
  type = list(
    object({
      test     = string,
      variable = string,
      values   = list(string)
    })
  )
  default = []
}

variable "policy_document" {
  description = "Adds a json file to the policy"
  type        = map(string)
  default     = {}
}