# Stack 2 of 3 — Azure Container Apps (Lab 4)
# Public Docker Hub image — no ACR. Consumption plan can scale toward zero.

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
  type    = string
  default = "python:3.9-bullseye"
}

locals {
  boot = file("${path.module}/../../../lab4-containers/boot.sh")
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
      name    = "jwz"
      image   = var.container_image
      cpu     = 0.25
      memory  = "0.5Gi"
      command = ["bash", "-c"]
      args    = [local.boot]

      env {
        name  = "JWZ_LAB"
        value = "4-containers"
      }
      env {
        name  = "PORT"
        value = "8080"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8080
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
  description = "Container App URL — install tracer yourself"
  value       = "https://${azurerm_container_app.lab4.ingress[0].fqdn}"
}

output "lab4_name" {
  value = azurerm_container_app.lab4.name
}
