provider "azurerm" {
  version = "> 1.0"
}

resource "azurerm_resource_group" "core" {
  name     = var.resGroup
  location = var.location
}
