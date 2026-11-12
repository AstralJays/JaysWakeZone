# Stack 3 of 3 — GKE + Flask CVE workload (Lab 5)
# 1× e2-small zonal — destroy promptly.

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
  type    = string
  default = "docker.io/library/python:3.9-bullseye"
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

resource "google_container_cluster" "lab5" {
  name     = "${var.name_prefix}-lab5"
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {}

  # Cheaper: no logging/monitoring extras beyond defaults where possible
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

  depends_on = [google_container_node_pool.lab5]
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
  value = google_container_cluster.lab5.name
}

output "lab5_url" {
  description = "Wait for LB IP — install cluster sensor yourself"
  value       = try("http://${kubernetes_service.jwz.status[0].load_balancer[0].ingress[0].ip}", "pending-lb")
}

output "lab5_kubeconfig_hint" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.lab5.name} --zone ${var.zone} --project ${var.project_id}"
}
