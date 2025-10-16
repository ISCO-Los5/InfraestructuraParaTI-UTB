variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "location of the resource group"
}

variable "admin_ip" {
  type        = string
  description = "admin ip address"
}
