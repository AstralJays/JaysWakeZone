# Stack 3 of 3 — GKE + JaysWakeZone Agentic API Lab (Lab 5)
# Publish YOURUSER/jwz-agent-lab then set container_image.

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

resource "google_container_node_pool" "lab5" {
  name       = "jwz"
  location   = var.zone
  cluster    = google_container_cluster.lab5.name
  node_count = 1

  node_config {
    machine_type = "e2-small"
    disk_size_gb = 30
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    labels = {
      lab = "5"
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

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.lab5.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.lab5.master_auth[0].cluster_ca_certificate)
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

  depends_on = [google_container_node_pool.lab5]
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
  description = "Agentic API Lab UI — install cluster sensor yourself"
  value       = try("http://${kubernetes_service.jwz.status[0].load_balancer[0].ingress[0].ip}", "pending-lb")
}

output "lab5_kubeconfig_hint" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.lab5.name} --zone ${var.zone} --project ${var.project_id}"
}
