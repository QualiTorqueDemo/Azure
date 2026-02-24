output "linux_vm_vmss_id" {
  value = azurerm_linux_virtual_machine_scale_set.vmss.id
}

output "linux_vm_vmss_unique_id" {
  value = azurerm_linux_virtual_machine_scale_set.vmss.unique_id
}

output "instance_private_ips" {
  description = "Private IP addresses of the VMSS instances"
  value       = join(", ", [for inst in data.azurerm_virtual_machine_scale_set.vmss.instances : inst.private_ip_address])
}