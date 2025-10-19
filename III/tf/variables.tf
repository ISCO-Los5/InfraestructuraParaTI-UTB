variable "resource_group_location" {
  description = "Ubicación del Resource Group"
  type        = string
  default     = "East US"
}

variable "controller_ip" {
  description = "IP pública del controlador que ejecuta Terraform/Ansible (formato: x.x.x.x/32)"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}/\\d{1,2}$", var.controller_ip))
    error_message = "La IP del controlador debe estar en formato CIDR (ej: 192.168.1.1/32)"
  }
}

variable "admin_username" {
  description = "Usuario administrador de la VM"
  type        = string
  default     = "azureuser"
}

variable "mysql_root_password" {
  description = "Contraseña root de MySQL"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.mysql_root_password) >= 12
    error_message = "La contraseña debe tener al menos 12 caracteres"
  }
}

variable "mysql_db" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "appdb"
}

variable "mysql_user" {
  description = "Usuario de MySQL para la aplicación"
  type        = string
  default     = "appuser"
}

variable "mysql_password" {
  description = "Contraseña del usuario de MySQL"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.mysql_password) >= 12
    error_message = "La contraseña debe tener al menos 12 caracteres"
  }
}

variable "docker_image" {
  description = "value"
  type        = string
  sensitive   = true
}
