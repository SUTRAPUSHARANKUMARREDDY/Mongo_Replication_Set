variable "create_new_resources" {
  description = "Determines whether to create new resources"
  type        = bool
  default     = true
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 3
}

variable "existing_vnet_name" {
  description = "Name of the existing VNet"
  type        = string
  default     = "SHARAN-SSH-vnet"
}

variable "new_vnet_name" {
  description = "Name of the new VNet"
  type        = string
  default     = "SHARAN-SSH-vnet"
}

variable "existing_resource_group_name" {
  description = "Name of the existing resource group"
  type        = string
  default     = "SHARAN"
}

variable "new_resource_group_name" {
  description = "Name of the new resource group"
  type        = string
  default     = "SHARAN_TWO"
}

variable "existing_subnet_name" {
  description = "Name of the existing subnet"
  type        = string
  default     = "default"
}

variable "new_subnet_name" {
  description = "Name of the new subnet"
  type        = string
  default     = "default"
}

locals {
  public_key = file("id_rsa.pub")
}

provider "azurerm" {
  features {}

  subscription_id = "864f0b0e-9580-411a-8908-f029c644a782"
  client_id       = "aac64bbe-59d0-44a0-a962-cb1e542d31c8"
  client_secret   = "BdK8Q~INMdLUy2yLKSqmEKdCs3RjNJwv4yZetczO"
  tenant_id       = "8f0e1988-e976-45c9-8118-89635fb510c6"
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
}

resource "azurerm_resource_group" "example" {
  count    = var.create_new_resources ? 1 : 0
  name     = var.new_resource_group_name
  location = "West US"
}

resource "azurerm_virtual_network" "example" {
  count               = var.create_new_resources ? 1 : 0
  name                = var.new_vnet_name
  location            = azurerm_resource_group.example[0].location
  resource_group_name = azurerm_resource_group.example[0].name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "example" {
  count                = var.create_new_resources ? 1 : 0
  name                 = var.new_subnet_name
  resource_group_name  = azurerm_resource_group.example[0].name
  virtual_network_name = azurerm_virtual_network.example[0].name
  address_prefixes     = ["10.1.1.0/24"]
}

data "azurerm_resource_group" "existing" {
  name  = var.existing_resource_group_name
}

data "azurerm_virtual_network" "existing" {
  name                = var.existing_vnet_name
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_subnet" "existing" {
  name                 = var.existing_subnet_name
  virtual_network_name = data.azurerm_virtual_network.existing.name
  resource_group_name  = data.azurerm_resource_group.existing.name
}

resource "azurerm_network_interface" "example" {
  count               = var.instance_count
  name                = "example-nic-${count.index}"
  location            = var.create_new_resources ? azurerm_resource_group.example[0].location : data.azurerm_resource_group.existing.location
  resource_group_name = var.create_new_resources ? azurerm_resource_group.example[0].name : data.azurerm_resource_group.existing.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.create_new_resources ? azurerm_subnet.example[0].id : data.azurerm_subnet.existing.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  count                 = var.instance_count
  name                  = "example-vm-${count.index}"
  location              = var.create_new_resources ? azurerm_resource_group.example[0].location : data.azurerm_resource_group.existing.location
  resource_group_name   = var.create_new_resources ? azurerm_resource_group.example[0].name : data.azurerm_resource_group.existing.name
  network_interface_ids = [azurerm_network_interface.example[count.index].id]
  size                  = "Standard_B1s"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name  = "example-vm-${count.index}"
  admin_username = "adminuser"
  admin_password = "P@ssw0rd1234!"

  admin_ssh_key {
    username   = "adminuser"
    public_key = local.public_key
  }

  tags = {
    Environment = "Dev"
    Role        = "MongoDB Instances"
  }

  disable_password_authentication = true
}


resource "azurerm_virtual_network_peering" "peer1" {
  count                        = var.create_new_resources && length(data.azurerm_virtual_network.existing) > 0 ? 1 : 0
  name                         = "peer1"
  resource_group_name          = azurerm_resource_group.example[0].name
  virtual_network_name         = azurerm_virtual_network.example[0].name
  remote_virtual_network_id    = length(data.azurerm_virtual_network.existing) > 0 ? data.azurerm_virtual_network.existing.id : null
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "peer2" {
  count                        = var.create_new_resources && length(data.azurerm_virtual_network.existing) > 0 ? 1 : 0
  name                         = "peer2"
  resource_group_name          = length(data.azurerm_resource_group.existing) > 0 ? data.azurerm_resource_group.existing.name : null
  virtual_network_name         = length(data.azurerm_virtual_network.existing) > 0 ? data.azurerm_virtual_network.existing.name : null
  remote_virtual_network_id    = azurerm_virtual_network.example[0].id
  allow_virtual_network_access = true
}

output "vm_private_ips" {
  value = var.instance_count > 0 ? azurerm_linux_virtual_machine.example.*.private_ip_address : []
}