# Stack 3 of 3 — AKS + Damn Vulnerable AI Agent (Lab 5)
# 1× Standard_B2s (4 GiB) — destroy promptly.
# Image: public Docker Hub opena2a/dvaa (no private registry / no build).

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
  description = "Public DVAA image — https://hub.docker.com/r/opena2a/dvaa"
  default     = "opena2a/dvaa:0.9.2"
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
    name   = "jwz-dvaa"
    labels = { app = "jwz-dvaa", lab = "5" }
  }

  spec {
    replicas = 1
    selector {
      match_labels = { app = "jwz-dvaa" }
    }
    template {
      metadata {
        labels = { app = "jwz-dvaa" }
      }
      spec {
        container {
          name              = "dvaa"
          image             = var.container_image
          image_pull_policy = "IfNotPresent"

          env {
            name  = "OPENA2A_TELEMETRY"
            value = "off"
          }

          port {
            name           = "dashboard"
            container_port = 9000
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 9000
            }
            initial_delay_seconds = 45
            period_seconds        = 15
            failure_threshold     = 6
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 9000
            }
            initial_delay_seconds = 90
            period_seconds        = 30
          }

          resources {
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
            limits = {
              cpu    = "1500m"
              memory = "3Gi"
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
    name = "jwz-dvaa"
  }
  spec {
    type     = "LoadBalancer"
    selector = { app = "jwz-dvaa" }
    port {
      name        = "dashboard"
      port        = 80
      target_port = 9000
    }
  }
}

output "lab5_cluster_name" {
  value = azurerm_kubernetes_cluster.lab5.name
}

output "lab5_url" {
  description = "DVAA dashboard (intentionally vulnerable — lab only). Install cluster sensor yourself."
  value       = try("http://${kubernetes_service.jwz.status[0].load_balancer[0].ingress[0].ip}", "pending-lb")
}

output "lab5_get_credentials" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.lab5.name} --name ${azurerm_kubernetes_cluster.lab5.name}"
}

output "lab5_port_forward_agents" {
  description = "Forward agent ports for HackMyAgent / curl against the fleet"
  value       = "kubectl port-forward deploy/jwz-dvaa 9000:9000 7003:7003"
}
