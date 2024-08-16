provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "banking-system-rg"
}

variable "location" {
  description = "Azure region"
  default     = "canada central"
}

variable "vnet_name" {
  description = "Name of the virtual network"
  default     = "banking-system-vnet"
}

variable "web_subnet_name" {
  description = "Name of the web subnet"
  default     = "web-subnet"
}

variable "business_subnet_name" {
  description = "Name of the business subnet"
  default     = "business-subnet"
}

variable "data_subnet_name" {
  description = "Name of the data subnet"
  default     = "data-subnet"
}

variable "bastion_subnet_name" {
  description = "Name of the bastion subnet"
  default     = "AzureBastionSubnet"
}

variable "nsg_name" {
  description = "Name of the network security group"
  default     = "banking-system-nsg"
}

variable "web_vm_name" {
  description = "Name of the web virtual machine"
  default     = "web-vm"
}

variable "business_vm_name" {
  description = "Name of the business virtual machine"
  default     = "business-vm"
}

variable "frontend_lb_name" {
  description = "Name of the frontend load balancer"
  default     = "frontend-lb"
}

variable "backend_lb_name" {
  description = "Name of the backend load balancer"
  default     = "backend-lb"
}

variable "primary_sql_server_name" {
  description = "Name of the primary SQL server"
  default     = "uniquetdprimarysqlserver"
}

variable "primary_db_name" {
  description = "Name of the primary database"
  default     = "uniquetdprimarydb"
}

variable "bastion_name" {
  description = "Name of the bastion host"
  default     = "banking-system-bastion"
}

variable "bastion_public_ip_name" {
  description = "Name of the bastion public IP"
  default     = "bastion-public-ip"
}

variable "admin_username" {
  description = "Admin username for VMs and SQL server"
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for VMs and SQL server"
  default     = "P@ssw0rd1234"
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnets
resource "azurerm_subnet" "web_subnet" {
  name                 = var.web_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "business_subnet" {
  name                 = var.business_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "data_subnet" {
  name                 = var.data_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = var.bastion_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.4.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Network Interface
resource "azurerm_network_interface" "web_nic" {
  count               = 3
  name                = "${var.web_vm_name}-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "web-nic-ipconfig"
    subnet_id                     = azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "business_nic" {
  count               = 1
  name                = "${var.business_vm_name}-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "business-nic-ipconfig"
    subnet_id                     = azurerm_subnet.business_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual Machines
resource "azurerm_windows_virtual_machine" "web_vm" {
  count               = 1
  name                = "${var.web_vm_name}-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_DS1_v2"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.web_nic[count.index].id,
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "business_vm" {
  count               = 1
  name                = "${var.business_vm_name}-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_DS1_v2"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.business_nic[count.index].id,
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

# Load Balancer
resource "azurerm_lb" "frontend_lb" {
  name                = var.frontend_lb_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "frontend"
    subnet_id            = azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb" "backend_lb" {
  name                = var.backend_lb_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "backend"
    subnet_id            = azurerm_subnet.business_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# SQL Servers
resource "azurerm_mssql_server" "primary_sql" {
  name                         = var.primary_sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password
}

# SQL Databases
resource "azurerm_mssql_database" "primary_db" {
  name                = var.primary_db_name
  server_id           = azurerm_mssql_server.primary_sql.id
  sku_name            = "S0"
}

# Azure Bastion
resource "azurerm_bastion_host" "bastion" {
  name                = var.bastion_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }
}

resource "azurerm_public_ip" "bastion_public_ip" {
  name                = var.bastion_public_ip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
