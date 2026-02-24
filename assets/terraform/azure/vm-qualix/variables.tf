variable "env_details" {
    type = object({
      vnet_name = string, 
      rg_name = string,
      env_id = string,
      subnet_id = string
    })
}




variable "vm_name" {
  type = string
  default = "MyVM"
  description = "VM Name"
}

variable "qualix_ip" {
  type = string
  default = "127.0.0.1"  
}

variable "source_snapshot_details" {
    type = object({
      snapshot_name = string, 
      snapshot_type = string,
      snapshot_rg = string,
      snapshot_username = string,
      snapshot_password = string
    })
}