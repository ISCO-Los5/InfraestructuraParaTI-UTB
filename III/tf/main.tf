terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0"
    }
  }

  # cloud {
  #   organization = "los-5"

  #   workspaces {
  #     name = "iii-app"
  #   }
  # }
}

provider "azurerm" {
  features {

  }
}

# ============================================
# RESOURCE GROUP
# ============================================
resource "azurerm_resource_group" "rg" {
  name     = "rg-los5"
  location = var.resource_group_location
}

# ============================================
# VIRTUAL NETWORK & SUBNETS
# ============================================
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-los5"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet para la VM de MySQL (privada)
resource "azurerm_subnet" "db_subnet" {
  name                 = "db-subnet-los5"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet para integración VNet del App Service
resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet-los5"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "app-service-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# ============================================
# NETWORK SECURITY GROUPS
# ============================================

# NSG para la VM de MySQL
resource "azurerm_network_security_group" "db_nsg" {
  name                = "db-nsg-los5"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Permitir SSH solo desde la IP del controlador
  security_rule {
    name                       = "AllowSSHFromController"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.controller_ip
    destination_address_prefix = "*"
  }

  # ⭐ CAMBIADO: Permitir MySQL desde toda la VNet (más permisivo pero funcional)
  security_rule {
    name                       = "AllowMySQLFromVNet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowMySQLFromAppService"
    priority                   = 115
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "AzureCloud" # Service Tag
    destination_address_prefix = "*"
  }

  # Denegar todo lo demás
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Asociar NSG a la subnet de DB
resource "azurerm_subnet_network_security_group_association" "db_nsg_assoc" {
  subnet_id                 = azurerm_subnet.db_subnet.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

# ============================================
# SSH KEY GENERATION
# ============================================
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_openssh
  filename        = "${path.module}/ssh_keys/mysql_vm_key.pem"
  file_permission = "0600"
}

# ============================================
# MYSQL VM - NETWORK INTERFACE
# ============================================
resource "azurerm_network_interface" "mysql_nic" {
  name                = "mysql-nic-los5"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.db_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
    public_ip_address_id          = azurerm_public_ip.mysql_public_ip.id
  }
}

# ============================================
# MYSQL VIRTUAL MACHINE
# ============================================
resource "azurerm_public_ip" "mysql_public_ip" {
  name                = "mysql-public-ip-los5"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_linux_virtual_machine" "mysql_vm" {
  name                  = "mysql-vm-los5"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.mysql_nic.id]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "mysql-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = "mysqlvm"
  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# ============================================
# APP SERVICE PLAN
# ============================================
resource "azurerm_service_plan" "app_plan" {
  name                = "app-service-plan-los5"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"

  tags = {
    Environment = "Production"
  }
}

# ============================================
# NODE.JS WEB APP
# ============================================
resource "azurerm_linux_web_app" "node_app" {
  name                = "node-app-los5-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.app_plan.id

  # Integración VNet para acceso privado a MySQL
  virtual_network_subnet_id = azurerm_subnet.app_subnet.id

  site_config {
    always_on              = false
    minimum_tls_version    = "1.2"
    ftps_state             = "Disabled"
    http2_enabled          = true
    vnet_route_all_enabled = true

    application_stack {
      docker_image_name = var.docker_image
    }
  }

  # Solo HTTPS
  https_only = true

  app_settings = {
    "MYSQL_HOST"     = azurerm_network_interface.mysql_nic.private_ip_address
    "MYSQL_PORT"     = "3306"
    "MYSQL_USER"     = var.mysql_user
    "MYSQL_PASSWORD" = var.mysql_password
    "MYSQL_DB"       = var.mysql_db
    "NODE_ENV"       = "production"
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# ============================================
# RANDOM STRING FOR UNIQUE NAMES
# ============================================
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ============================================
# OUTPUTS
# ============================================
output "mysql_private_ip" {
  description = "IP privada de la VM MySQL"
  value       = azurerm_network_interface.mysql_nic.private_ip_address
}

output "app_service_url" {
  description = "URL del App Service"
  value       = "https://${azurerm_linux_web_app.node_app.default_hostname}"
}

output "app_service_name" {
  description = "Nombre del App Service"
  value       = azurerm_linux_web_app.node_app.name
}

output "resource_group_name" {
  description = "Nombre del Resource Group"
  value       = azurerm_resource_group.rg.name
}

output "ssh_private_key_path" {
  description = "Ruta a la llave SSH privada"
  value       = local_sensitive_file.private_key.filename
  sensitive   = true
}

output "ssh_connection_command" {
  description = "Comando para conectarse a la VM MySQL vía SSH"
  value       = "ssh -i ${local_sensitive_file.private_key.filename} ${var.admin_username}@${azurerm_network_interface.mysql_nic.private_ip_address}"
  sensitive   = true
}


