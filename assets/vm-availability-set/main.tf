resource "random_id" "id" {
  byte_length = 2
}

resource "azurerm_resource_group" "rg" {
  count = var.create_resource_group ? 1 : 0

  location = var.location
  name     = coalesce(var.resource_group_name, "tf-vmmod-basic-${random_id.id.hex}")
}

locals {
  resource_group = {
    name     = try(azurerm_resource_group.rg[0].name, var.resource_group_name)
    location = var.location
  }
}

module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "5.0.0"

  resource_group_name = local.resource_group.name
  use_for_each        = true
  vnet_location       = local.resource_group.location
  address_space       = ["192.168.0.0/24"]
  vnet_name           = "vnet-vm-${random_id.id.hex}"
  subnet_names        = ["subnet-virtual-machine"]
  subnet_prefixes     = ["192.168.0.0/28"]
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "azurerm_public_ip" "pip" {
  count = var.create_public_ip ? 2 : 0

  allocation_method   = "Static"
  location            = local.resource_group.location
  name                = "pip-${random_id.id.hex}-${count.index}"
  resource_group_name = local.resource_group.name
}

# --- Linux VM (native resource) ---

resource "azurerm_network_interface" "linux_nic" {
  location            = local.resource_group.location
  name                = "linux-nic-${random_id.id.hex}"
  resource_group_name = local.resource_group.name

  ip_configuration {
    name                          = "primary"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = try(azurerm_public_ip.pip[0].id, null)
    subnet_id                     = module.vnet.vnet_subnets[0]
  }
}

resource "azurerm_linux_virtual_machine" "linux" {
  admin_username                  = "azureuser"
  location                        = local.resource_group.location
  name                            = "ubuntu-${random_id.id.hex}"
  network_interface_ids           = [azurerm_network_interface.linux_nic.id]
  resource_group_name             = local.resource_group.name
  size                            = var.size
  allow_extension_operations      = false
  encryption_at_host_enabled      = false

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  boot_diagnostics {}

  depends_on = [azurerm_key_vault_access_policy.des]
}

resource "azurerm_managed_disk" "linux_data" {
  count = 2

  create_option          = "Empty"
  disk_size_gb           = 1
  location               = local.resource_group.location
  name                   = "linuxdisk${random_id.id.hex}${count.index}"
  resource_group_name    = local.resource_group.name
  storage_account_type   = "Standard_LRS"
  disk_encryption_set_id = azurerm_disk_encryption_set.example.id
}

resource "azurerm_virtual_machine_data_disk_attachment" "linux_data" {
  count = 2

  caching            = "ReadWrite"
  lun                = count.index
  managed_disk_id    = azurerm_managed_disk.linux_data[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.linux.id
}

resource "azurerm_network_interface_security_group_association" "linux_nic" {
  network_interface_id      = azurerm_network_interface.linux_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# --- Windows VM (native resource) ---

resource "random_password" "win_password" {
  length      = 20
  lower       = true
  upper       = true
  special     = true
  min_lower   = 1
  min_upper   = 1
  min_special = 1
}

resource "azurerm_network_interface" "windows_nic" {
  count = 2

  location            = local.resource_group.location
  name                = "win-nic${count.index}"
  resource_group_name = local.resource_group.name

  ip_configuration {
    name                          = "nic"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = count.index == 0 ? try(azurerm_public_ip.pip[1].id, null) : null
    subnet_id                     = module.vnet.vnet_subnets[0]
  }
}

resource "azurerm_network_interface_security_group_association" "windows_nic" {
  count = length(azurerm_network_interface.windows_nic)

  network_interface_id      = azurerm_network_interface.windows_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "windows" {
  admin_password                  = random_password.win_password.result
  admin_username                  = "azureuser"
  location                        = local.resource_group.location
  name                            = "windows-${random_id.id.hex}"
  network_interface_ids           = azurerm_network_interface.windows_nic[*].id
  resource_group_name             = local.resource_group.name
  size                            = var.size
  allow_extension_operations      = false
  encryption_at_host_enabled      = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  boot_diagnostics {}

  depends_on = [azurerm_key_vault_access_policy.des]
}

resource "azurerm_managed_disk" "windows_data" {
  count = 2

  create_option          = "Empty"
  disk_size_gb           = 1
  location               = local.resource_group.location
  name                   = "windowsdisk${random_id.id.hex}${count.index}"
  resource_group_name    = local.resource_group.name
  storage_account_type   = "Standard_LRS"
  disk_encryption_set_id = azurerm_disk_encryption_set.example.id
}

resource "azurerm_virtual_machine_data_disk_attachment" "windows_data" {
  count = 2

  caching            = "ReadWrite"
  lun                = count.index
  managed_disk_id    = azurerm_managed_disk.windows_data[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.windows.id
}

resource "local_file" "ssh_private_key" {
  filename = "${path.module}/key.pem"
  content  = tls_private_key.ssh.private_key_pem
}

data "azurerm_public_ip" "pip" {
  count = var.create_public_ip ? 2 : 0

  name                = azurerm_public_ip.pip[count.index].name
  resource_group_name = local.resource_group.name

  depends_on = [azurerm_linux_virtual_machine.linux, azurerm_windows_virtual_machine.windows]
}
