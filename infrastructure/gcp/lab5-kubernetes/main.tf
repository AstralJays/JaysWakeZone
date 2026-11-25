# Stack 3 of 3 — GKE + WakeBot + in-cluster Ollama on GPU (Lab 5)
# Publish YOURUSER/jwz-agent-lab then set container_image.
# 1× e2-standard-2 (app + Upwind headroom) + 1× n1-standard-4 + T4 (Ollama) — destroy promptly (GPU $).
# Node RAM sized for Upwind Sensor (≥4 GiB recommended) + Cluster Manager (~2 GiB) — SA installs Upwind.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "name_prefix" {
  type    = string
  default = "jayswakezone"
}

variable "container_image" {
  type        = string
  description = "Docker Hub image you published from lab5-agentic/"
  default     = "docker.io/YOURUSER/jwz-agent-lab:0.1.0"
}

variable "ollama_model" {
  type        = string
  description = "Model pulled into in-cluster Ollama"
  default     = "llama3.2"
}

variable "gpu_type" {
  type        = string
  description = "GKE accelerator type for Ollama"
  default     = "nvidia-tesla-t4"
}

resource "google_container_cluster" "lab5" {
  name     = "${var.name_prefix}-lab5"
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {}

  logging_service    = "none"
  monitoring_service = "none"

  release_channel {
    channel = "REGULAR"
  }

  deletion_protection = false
}

resource "google_container_node_pool" "cpu" {
  name       = "jwz-cpu"
  location   = var.zone
  cluster    = google_container_cluster.lab5.name
  node_count = 1

  # e2-standard-2 = 2 vCPU / 8 GiB — Upwind ≥4 GiB guidance + Cluster Manager headroom
  node_config {
    machine_type = "e2-standard-2"
    disk_size_gb = 40
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    labels = {
      lab      = "5"
      workload = "cpu"
    }
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

resource "google_container_node_pool" "gpu" {
  name       = "jwz-gpu"
  location   = var.zone
  cluster    = google_container_cluster.lab5.name
  node_count = 1

  node_config {
    machine_type = "n1-standard-4"
    disk_size_gb = 100
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    labels = {
      lab      = "5"
      workload = "gpu"
    }
    metadata = {
      disable-legacy-endpoints = "true"
    }
    guest_accelerator {
      type  = var.gpu_type
      count = 1
      gpu_driver_installation_config {
        gpu_driver_version = "DEFAULT"
      }
    }
    taint {
      key    = "nvidia.com/gpu"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.lab5.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.lab5.master_auth[0].cluster_ca_certificate)
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

          # Leave RAM for Upwind Sensor DaemonSet on the GPU node (~15 GiB on n1-standard-4)
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

  depends_on = [google_container_node_pool.gpu]
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
    google_container_node_pool.cpu,
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
  value = google_container_cluster.lab5.name
}

output "lab5_url" {
  description = "WakeBot UI — install cluster sensor yourself"
  value       = try("http://${kubernetes_service.jwz.status[0].load_balancer[0].ingress[0].ip}", "pending-lb")
}

output "lab5_ollama" {
  value = "in-cluster Service ollama:11434 (GPU) · model ${var.ollama_model}"
}

output "lab5_kubeconfig_hint" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.lab5.name} --zone ${var.zone} --project ${var.project_id}"
}
