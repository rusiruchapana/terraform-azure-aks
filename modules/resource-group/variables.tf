variable "name" {
  description = "Name of the Azure Resource Group"
  type = string
}

variable "location" {
    description = "Region of the Azure Resources creation"
    type = string
}

variable "tags" {
  description = "Tags to Apply to the Resource Group"
  type = map(string)
  default = {}
}