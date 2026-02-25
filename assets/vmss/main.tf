resource "random_id" "id" {
  byte_length = 2
}

resource "azurerm_resource_group" "rg" {
  count = var.create_resource_group ? 1 : 0

  location = var.location
  name     = coalesce(var.resource_group_name, "tf-vmmod-vmss-${random_id.id.hex}")
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
  vnet_name           = "vnet-vmss-${random_id.id.hex}"
  subnet_names        = ["subnet-vmss"]
  subnet_prefixes     = ["192.168.0.0/24"]
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "vmss-${random_id.id.hex}"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  sku                 = var.size
  instances           = var.instances
  admin_username      = "azureuser"
  upgrade_mode        = "Manual"

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "nic-vmss-${random_id.id.hex}"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = module.vnet.vnet_subnets[0]
    }

    network_security_group_id = azurerm_network_security_group.nsg.id
  }
}

resource "local_file" "ssh_private_key" {
  filename = "${path.module}/key.pem"
  content  = tls_private_key.ssh.private_key_pem
}

data "azurerm_virtual_machine_scale_set" "vmss" {
  name                = azurerm_linux_virtual_machine_scale_set.vmss.name
  resource_group_name = local.resource_group.name
  // todo: a comment

  depends_on = [azurerm_linux_virtual_machine_scale_set.vmss]
}
