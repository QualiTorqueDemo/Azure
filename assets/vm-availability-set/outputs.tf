output "linux_public_ip" {
  value = try(data.azurerm_public_ip.pip[0].ip_address, null)
}

output "linux_vm_id" {
  value = azurerm_linux_virtual_machine.linux.id
}

output "windows_public_ip" {
  value = try(data.azurerm_public_ip.pip[1].ip_address, null)
}

output "windows_vm_id" {
  value = azurerm_windows_virtual_machine.windows.id
}

output "windows_vm_password" {
  value     = random_password.win_password.result
  sensitive = true
}
