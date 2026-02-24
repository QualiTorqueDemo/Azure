variable "location" {
  type = string
}

variable "env_start_address" {
  type = string
  default = "10.0.0.0"
}

variable "env_id" {
  type = string
  default = ""
}

variable "source_cidr" {
  type = string
  default = "0.0.0.0/0"
  description = "IP Range that can access the deployed VMs"  
}