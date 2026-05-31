variable "principal_id" {
  description = "Principal ID of the identity receiving the role assignment."
  type        = string
}

variable "scope" {
  description = "Azure resource scope where the role will be assigned."
  type        = string
}

variable "role_definition_name" {
  description = "Azure built-in role definition name."
  type        = string
}