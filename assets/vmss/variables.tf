variable "create_resource_group" {
  type     = bool
  default  = true
  nullable = false
}

variable "location" {
  type     = string
  default  = "westus2"
  nullable = false
}

variable "resource_group_name" {
  type    = string
  default = null
}

variable "size" {
  type     = string
  default  = "Standard_A1_v2"
  nullable = false
}

variable "instances" {
  description = "Number of VM instances in the scale set"
  type        = number
  default     = 2
  nullable    = false
}