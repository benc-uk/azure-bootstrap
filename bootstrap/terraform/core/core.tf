provider "azurerm" {
  version = "> 1.0"
}

resource "azurerm_resource_group" "core" {
  name     = var.RES_GROUP
  location = var.LOCATION
}
