terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  version = "~> 2.10"
  features {}
}

variable "name_prefix" {
  type        = string
  description = "A prefix for the naming scheme as part of prefix-base-suffix."
}

variable "name_base" {
  type        = string
  description = "A base for the naming scheme as part of prefix-base-suffix."
}

variable "name_suffix" {
  type        = string
  description = "A suffix for the naming scheme as part of prefix-base-suffix."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
}

locals {
  base_name       = "${var.name_prefix}-${var.name_base}-${var.name_suffix}"
  web_subnet_name = "web-subnet"
}

resource "azurerm_resource_group" "group" {
  name     = local.base_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.base_name}-vnet"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "web" {
  name                 = local.web_subnet_name
  resource_group_name  = azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "web-subnet-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_app_service_plan" "plan" {
  name                = "${local.base_name}-plan"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "appsvc" {
  name                = "${local.base_name}-app"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  app_service_plan_id = azurerm_app_service_plan.plan.id
  
  site_config {
    always_on          = true
    linux_fx_version = "DOCKER|mcr.microsoft.com/dotnet/core/samples:aspnetapp"
  }
  
  app_settings = {
    DOCKER_CUSTOM_IMAGE_NAME            = "https://mcr.microsoft.com/dotnet/core/samples:aspnetapp"
    DOCKER_REGISTRY_SERVER_URL          = "https://mcr.microsoft.com"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITE_VNET_ROUTE_ALL              = 1
  }
  
  lifecycle {
    ignore_changes = [
      app_settings.DOCKER_CUSTOM_IMAGE_NAME,
      site_config.0.linux_fx_version,
      site_config.0.scm_type
    ]
  }

  # identity {
  #   type = "SystemAssigned"
  # }
}

resource "azurerm_app_service_virtual_network_swift_connection" "web" {
  app_service_id = azurerm_app_service.appsvc.id
  subnet_id      = azurerm_subnet.web.id
}