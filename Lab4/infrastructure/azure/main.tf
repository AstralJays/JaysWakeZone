# Stack 2 of 3 — Azure Container Apps (Lab 4)
# Public OWASP Juice Shop — no ACR / no build.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "name_prefix" {
  type    = string
  default = "jayswakezone"
}

variable "container_image" {
  type        = string
  default     = "bkimminich/juice-shop:latest"
  description = "Public Docker Hub image (OWASP Juice Shop)."
}

variable "container_port" {
  type    = number
  default = 3000
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_resource_group" "lab4" {
  name     = "${var.name_prefix}-lab4-rg"
  location = var.location
  tags = {
    Project = "JaysWakeZone"
    Stack   = "lab4-containers"
    Lab     = "4"
  }
}

resource "azurerm_log_analytics_workspace" "lab4" {
  name                = "${var.name_prefix}-lab4-law"
  location            = azurerm_resource_group.lab4.location
  resource_group_name = azurerm_resource_group.lab4.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "lab4" {
  name                       = "${var.name_prefix}-lab4-env"
  location                   = azurerm_resource_group.lab4.location
  resource_group_name        = azurerm_resource_group.lab4.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.lab4.id
}

resource "azurerm_container_app" "lab4" {
  name                         = "${var.name_prefix}-lab4-${random_string.suffix.result}"
  container_app_environment_id = azurerm_container_app_environment.lab4.id
  resource_group_name          = azurerm_resource_group.lab4.name
  revision_mode                = "Single"

  template {
    min_replicas = 0
    max_replicas = 2

    container {
      name   = "juice-shop"
      image  = var.container_image
      cpu    = 0.5
      memory = "1Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = var.container_port
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = {
    Project = "JaysWakeZone"
    Lab     = "4"
  }
}

output "lab4_url" {
  description = "OWASP Juice Shop — install tracer yourself"
  value       = "https://${azurerm_container_app.lab4.ingress[0].fqdn}"
}

output "lab4_name" {
  value = azurerm_container_app.lab4.name
}

output "lab4_image" {
  value = var.container_image
}
