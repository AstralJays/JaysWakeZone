# Stack 3 of 3 — AKS + Flask CVE workload (Lab 5)
# 1× Standard_B2s — destroy promptly.

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
  type    = string
  default = "python:3.9-bullseye"
}

locals {
  boot = <<-BOOT
    set -e
    export JWZ_LAB=5-kubernetes PORT=8080
    pip install --no-cache-dir flask==2.0.3 werkzeug==2.0.3
    cat >/tmp/jwz_app.py <<'PY'
    import os
    from flask import Flask
    app = Flask(__name__)
    LAB = os.environ.get("JWZ_LAB", "5-kubernetes")
    @app.route("/")
    def index():
        return {"status": "running", "demo": "cve-detection", "lab": LAB}
    @app.route("/health")
    def health():
        return {"ok": True}
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
    PY
    exec python /tmp/jwz_app.py
  BOOT
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
    name   = "jwz-cve-flask"
    labels = { app = "jwz-cve-flask", lab = "5" }
  }

  spec {
    replicas = 1
    selector {
      match_labels = { app = "jwz-cve-flask" }
    }
    template {
      metadata {
        labels = { app = "jwz-cve-flask" }
      }
      spec {
        container {
          name  = "app"
          image = var.container_image
          env {
            name  = "JWZ_LAB"
            value = "5-kubernetes"
          }
          env {
            name  = "PORT"
            value = "8080"
          }
          command = ["bash", "-c"]
          args    = [local.boot]
          port {
            container_port = 8080
          }
          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }

  depends_on = [azurerm_kubernetes_cluster.lab5]
}

resource "kubernetes_service" "jwz" {
  metadata {
    name = "jwz-cve-flask"
  }
  spec {
    type     = "LoadBalancer"
    selector = { app = "jwz-cve-flask" }
    port {
      port        = 80
      target_port = 8080
    }
  }
}

output "lab5_cluster_name" {
  value = azurerm_kubernetes_cluster.lab5.name
}

output "lab5_url" {
  description = "Wait for LB IP — install cluster sensor yourself"
  value       = try("http://${kubernetes_service.jwz.status[0].load_balancer[0].ingress[0].ip}", "pending-lb")
}

output "lab5_get_credentials" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.lab5.name} --name ${azurerm_kubernetes_cluster.lab5.name}"
}
