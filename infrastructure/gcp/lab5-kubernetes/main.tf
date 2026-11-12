# Stack 3 of 3 — GKE + Damn Vulnerable AI Agent (Lab 5)
# 1× e2-medium zonal — destroy promptly.
# Image: public Docker Hub opena2a/dvaa (no private registry / no build).

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
  description = "Public DVAA image — https://hub.docker.com/r/opena2a/dvaa"
  default     = "docker.io/opena2a/dvaa:0.9.2"
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
    # DVAA fleet needs ~4 GiB headroom
    machine_type = "e2-medium"
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

  depends_on = [google_container_node_pool.lab5]
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
  value = google_container_cluster.lab5.name
}

output "lab5_url" {
  description = "DVAA dashboard (intentionally vulnerable — lab only). Install cluster sensor yourself."
  value       = try("http://${kubernetes_service.jwz.status[0].load_balancer[0].ingress[0].ip}", "pending-lb")
}

output "lab5_kubeconfig_hint" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.lab5.name} --zone ${var.zone} --project ${var.project_id}"
}

output "lab5_port_forward_agents" {
  description = "Forward agent ports for HackMyAgent / curl against the fleet"
  value       = "kubectl port-forward deploy/jwz-dvaa 9000:9000 7003:7003"
}
