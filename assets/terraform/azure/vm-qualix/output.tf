output "vm_id" {
  value = azurerm_virtual_machine.my-vm.id
}

output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "vm_rdp_link" {
  value = length(module.qualix_windows_vm_link) == 1 ? module.qualix_windows_vm_link[0].http_link : ""
  # sensitive = true
}

# output "vm_rdp_readonly_link" {
#   value = length(module.qualix_windows_vm_link) == 1 ? module.qualix_windows_vm_link[0].http_readonly_link : ""
#   # sensitive = true
# }

output "qualix_ip" {
  value = var.qualix_ip
}