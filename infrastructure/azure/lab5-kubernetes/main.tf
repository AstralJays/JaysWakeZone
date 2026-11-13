# Stack 3 of 3 — AKS + JaysWakeZone Agentic API Lab (Lab 5)
# Publish YOURUSER/jwz-agent-lab then set container_image.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
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
  description = "Docker Hub image you published from lab5-agentic/"
  default     = "YOURUSER/jwz-agent-lab:0.1.0"
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_resource_group" "lab5" {
  name     = "${var.name_prefix}-lab5-rg"
  location = var.location
  tags = {
    Project = "JaysWakeZone"
    Stack   = "lab5-kubernetes"
    Lab     = "5"
  }
}

resource "azurerm_kubernetes_cluster" "lab5" {
  name                = "${var.name_prefix}-lab5-${random_string.suffix.result}"
  location            = azurerm_resource_group.lab5.location
  resource_group_name = azurerm_resource_group.lab5.name
  dns_prefix          = "${var.name_prefix}-lab5"
  sku_tier            = "Free"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Project = "JaysWakeZone"
    Lab     = "5"
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.lab5.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.lab5.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.lab5.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.lab5.kube_config[0].cluster_ca_certificate)
}

resource "kubernetes_deployment" "jwz" {
  metadata {
    name   = "jwz-agent-lab"
    labels = { app = "jwz-agent-lab", lab = "5" }
  }

  spec {
    replicas = 1
    selector {
      match_labels = { app = "jwz-agent-lab" }
    }
    template {
      metadata {
        labels = { app = "jwz-agent-lab" }
      }
      spec {
        container {
          name              = "app"
          image             = var.container_image
          image_pull_policy = "IfNotPresent"

          env {
            name  = "PORT"
            value = "8080"
          }

          port {
            name           = "http"
            container_port = 8080
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 8
            period_seconds        = 10
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [azurerm_kubernetes_cluster.lab5]
}

resource "kubernetes_service" "jwz" {
  metadata {
    name = "jwz-agent-lab"
  }
  spec {
    type     = "LoadBalancer"
    selector = { app = "jwz-agent-lab" }
    port {
      name        = "http"
      port        = 80
      target_port = 8080
    }
  }
}

output "lab5_cluster_name" {
  value = azurerm_kubernetes_cluster.lab5.name
}

output "lab5_url" {
  description = "Agentic API Lab UI — install cluster sensor yourself"
  value       = try("http://${kubernetes_service.jwz.status[0].load_balancer[0].ingress[0].ip}", "pending-lb")
}

output "lab5_get_credentials" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.lab5.name} --name ${azurerm_kubernetes_cluster.lab5.name}"
}
