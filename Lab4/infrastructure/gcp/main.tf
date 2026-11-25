# Stack 2 of 3 — Cloud Run (Lab 4)
# Public OWASP Juice Shop — no GAR / no build.
# Distinct from lab1-3 Lab 3 serverless (Lambda-style) Cloud Run.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "name_prefix" {
  type    = string
  default = "jayswakezone"
}

variable "container_image" {
  type        = string
  default     = "docker.io/bkimminich/juice-shop:latest"
  description = "Public Docker Hub image (OWASP Juice Shop)."
}

variable "container_port" {
  type    = number
  default = 3000
}

resource "google_cloud_run_v2_service" "lab4" {
  name     = "${var.name_prefix}-lab4"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = var.container_image
      ports {
        container_port = var.container_port
      }
      resources {
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }
    }
    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }
  }

  labels = {
    project = "jayswakezone"
    stack   = "lab4-containers"
    lab     = "4"
  }
}

resource "google_cloud_run_v2_service_iam_member" "lab4_public" {
  project  = var.project_id
  location = google_cloud_run_v2_service.lab4.location
  name     = google_cloud_run_v2_service.lab4.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "lab4_url" {
  description = "OWASP Juice Shop — install tracer yourself"
  value       = google_cloud_run_v2_service.lab4.uri
}

output "lab4_service_name" {
  value = google_cloud_run_v2_service.lab4.name
}

output "lab4_image" {
  value = var.container_image
}
