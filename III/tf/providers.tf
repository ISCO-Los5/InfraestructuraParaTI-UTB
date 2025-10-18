terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }

  cloud {
    organization = "los-5"

    workspaces {
      name = "iii-app"
    }
  }
}
