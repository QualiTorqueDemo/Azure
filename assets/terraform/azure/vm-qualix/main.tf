## <https://www.terraform.io/docs/providers/azurerm/index.html>
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.42.0"
    }
  }
}

provider "azurerm" {
  features {}
}

## <https://www.terraform.io/docs/providers/azurerm/r/resource_group.html>

data "azurerm_virtual_network" "env_vnet" {
  name                = var.env_details.vnet_name
  resource_group_name = var.env_details.rg_name
}


resource "azurerm_public_ip" "public_ip" {
  name                = "${var.vm_name}-public-ip"
  resource_group_name = data.azurerm_virtual_network.env_vnet.resource_group_name
  location            = data.azurerm_virtual_network.env_vnet.location
  allocation_method   = "Static"
}

## <https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface>
resource "azurerm_network_interface" "vm-nic" {
  name                = "${var.vm_name}-nic"
  resource_group_name = data.azurerm_virtual_network.env_vnet.resource_group_name
  location            = data.azurerm_virtual_network.env_vnet.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.env_details.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

data "azurerm_snapshot" "source_snapshot" {
  name = var.source_snapshot_details.snapshot_name
  resource_group_name = var.source_snapshot_details.snapshot_rg
}

resource "azurerm_managed_disk" "my-vm-disk" {
  name = "${var.vm_name}-disk"
  resource_group_name = data.azurerm_virtual_network.env_vnet.resource_group_name
  location            = data.azurerm_virtual_network.env_vnet.location
  storage_account_type = "StandardSSD_LRS"
  create_option = "Copy"
  source_resource_id = data.azurerm_snapshot.source_snapshot.id
  disk_size_gb = data.azurerm_snapshot.source_snapshot.disk_size_gb
}

## <https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/availability_set>
resource "azurerm_availability_set" "DemoAset" {
  name                = "${var.vm_name}-ASet"
  resource_group_name = data.azurerm_virtual_network.env_vnet.resource_group_name
  location            = data.azurerm_virtual_network.env_vnet.location
}

## <https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine>
resource "azurerm_virtual_machine" "my-vm" {
  name                = var.vm_name
  resource_group_name = data.azurerm_virtual_network.env_vnet.resource_group_name
  location            = data.azurerm_virtual_network.env_vnet.location
  vm_size             = "Standard_DS1_v2"
  availability_set_id = azurerm_availability_set.DemoAset.id
  network_interface_ids = [ azurerm_network_interface.vm-nic.id,]
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name              = azurerm_managed_disk.my-vm-disk.name
    create_option     = "Attach"
    os_type           = var.source_snapshot_details.snapshot_type
    managed_disk_id   = azurerm_managed_disk.my-vm-disk.id
    managed_disk_type = azurerm_managed_disk.my-vm-disk.storage_account_type
  }
}

module "qualix_windows_vm_link" {
    count = var.qualix_ip != "127.0.0.1" ? 1 : 0
    source = "./qualix_link_maker"
    qualix_ip = var.qualix_ip
    protocol = "rdp"
    connection_port = 3389
    target_ip_address = azurerm_public_ip.public_ip.ip_address
    target_username = var.source_snapshot_details.snapshot_username
    target_password = var.source_snapshot_details.snapshot_password
}