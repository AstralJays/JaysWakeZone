# Stack 3 of 3 — AKS + WakeBot + in-cluster Ollama on GPU (Lab 5)
# Publish YOURUSER/jwz-agent-lab then set container_image.
# 1× D2s_v5 (app + Upwind headroom) + 1× NC4as_T4_v3 (Ollama) — destroy promptly (GPU $).
# Node RAM sized for Upwind Sensor (≥4 GiB recommended) + Cluster Manager (~2 GiB) — SA installs Upwind.

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
  description = "Docker Hub image you published from Lab5/"
  default     = "YOURUSER/jwz-agent-lab:0.1.0"
}

variable "ollama_model" {
  type        = string
  description = "Model pulled into in-cluster Ollama"
  default     = "llama3.2"
}

variable "gpu_vm_size" {
  type        = string
  description = "GPU node pool size for Ollama (T4)"
  default     = "Standard_NC4as_T4_v3"
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

  # D2s_v5 = 2 vCPU / 8 GiB — Upwind ≥4 GiB guidance + Cluster Manager headroom
  default_node_pool {
    name       = "cpu"
    node_count = 1
    vm_size    = "Standard_D2s_v5"
    node_labels = {
      workload = "cpu"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Project = "JaysWakeZone"
    Lab     = "5"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "gpu" {
  name                  = "gpu"
  kubernetes_cluster_id     = azurerm_kubernetes_cluster.lab5.id
  vm_size               = var.gpu_vm_size
  node_count            = 1
  mode                  = "User"
  os_disk_size_gb       = 100
  node_labels = {
    workload = "gpu"
  }
  node_taints = [
    "nvidia.com/gpu=true:NoSchedule",
  ]
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.lab5.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.lab5.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.lab5.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.lab5.kube_config[0].cluster_ca_certificate)
}

resource "kubernetes_daemon_set_v1" "nvidia_device_plugin" {
  metadata {
    name      = "nvidia-device-plugin-daemonset"
    namespace = "kube-system"
    labels    = { name = "nvidia-device-plugin-ds" }
  }

  spec {
    selector {
      match_labels = { name = "nvidia-device-plugin-ds" }
    }
    strategy {
      type = "RollingUpdate"
    }
    template {
      metadata {
        labels = { name = "nvidia-device-plugin-ds" }
      }
      spec {
        toleration {
          key      = "nvidia.com/gpu"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        priority_class_name = "system-node-critical"
        container {
          image = "nvcr.io/nvidia/k8s-device-plugin:v0.14.5"
          name  = "nvidia-device-plugin-ctr"
          env {
            name  = "FAIL_ON_INIT_ERROR"
            value = "false"
          }
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }
          volume_mount {
            name       = "device-plugin"
            mount_path = "/var/lib/kubelet/device-plugins"
          }
        }
        volume {
          name = "device-plugin"
          host_path {
            path = "/var/lib/kubelet/device-plugins"
          }
        }
      }
    }
  }

  depends_on = [azurerm_kubernetes_cluster_node_pool.gpu]
}

resource "kubernetes_deployment" "ollama" {
  metadata {
    name   = "ollama"
    labels = { app = "ollama", lab = "5" }
  }

  wait_for_rollout = false

  spec {
    replicas = 1
    selector {
      match_labels = { app = "ollama" }
    }
    template {
      metadata {
        labels = { app = "ollama" }
      }
      spec {
        node_selector = {
          workload = "gpu"
        }
        toleration {
          key      = "nvidia.com/gpu"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }
        container {
          name  = "ollama"
          image = "ollama/ollama:latest"

          port {
            name           = "http"
            container_port = 11434
          }

          # Leave RAM for Upwind Sensor DaemonSet on the GPU node
          resources {
            requests = {
              cpu              = "1"
              memory           = "2Gi"
              "nvidia.com/gpu" = "1"
            }
            limits = {
              cpu              = "2"
              memory           = "6Gi"
              "nvidia.com/gpu" = "1"
            }
          }

          volume_mount {
            name       = "ollama-data"
            mount_path = "/root/.ollama"
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 11434
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }
        }
        volume {
          name = "ollama-data"
          empty_dir {}
        }
      }
    }
  }

  depends_on = [
    azurerm_kubernetes_cluster_node_pool.gpu,
    kubernetes_daemon_set_v1.nvidia_device_plugin,
  ]
}

resource "kubernetes_service" "ollama" {
  metadata {
    name = "ollama"
  }
  spec {
    selector = { app = "ollama" }
    port {
      name        = "http"
      port        = 11434
      target_port = 11434
    }
  }

  depends_on = [kubernetes_deployment.ollama]
}

resource "kubernetes_job_v1" "ollama_pull" {
  metadata {
    name = "ollama-pull-model"
  }

  wait_for_completion = false

  spec {
    backoff_limit = 8
    template {
      metadata {
        labels = { app = "ollama-pull" }
      }
      spec {
        restart_policy = "OnFailure"
        container {
          name  = "pull"
          image = "ollama/ollama:latest"
          env {
            name  = "OLLAMA_HOST"
            value = "http://ollama:11434"
          }
          command = ["ollama", "pull", var.ollama_model]
        }
      }
    }
  }

  depends_on = [kubernetes_service.ollama]
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
        node_selector = {
          workload = "cpu"
        }
        container {
          name              = "app"
          image             = var.container_image
          image_pull_policy = "IfNotPresent"

          env {
            name  = "PORT"
            value = "8080"
          }
          env {
            name  = "OLLAMA_BASE_URL"
            value = "http://ollama.default.svc.cluster.local:11434/v1"
          }
          env {
            name  = "OLLAMA_MODEL"
            value = var.ollama_model
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

  depends_on = [
    azurerm_kubernetes_cluster.lab5,
    kubernetes_service.ollama,
  ]
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
  description = "WakeBot UI — install cluster sensor yourself"
  value       = try("http://${kubernetes_service.jwz.status[0].load_balancer[0].ingress[0].ip}", "pending-lb")
}

output "lab5_ollama" {
  value = "in-cluster Service ollama:11434 (GPU) · model ${var.ollama_model}"
}

output "lab5_get_credentials" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.lab5.name} --name ${azurerm_kubernetes_cluster.lab5.name}"
}
