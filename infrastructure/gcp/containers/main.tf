# Stack 2 of 3 — Cloud Run containers track (Lab 4)
# Distinct from labs-1-3 Lab 3 serverless service. Scale-to-zero friendly.

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
  type    = string
  default = "docker.io/library/python:3.9-bullseye"
}

locals {
  boot = file("${path.module}/../../../lab4-containers/boot.sh")
}

resource "google_cloud_run_v2_service" "lab4" {
  name     = "${var.name_prefix}-lab4"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image   = var.container_image
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
      ports {
        container_port = 8080
      }
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
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
    stack   = "containers"
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
  description = "Cloud Run URL — install tracer yourself"
  value       = google_cloud_run_v2_service.lab4.uri
}

output "lab4_service_name" {
  value = google_cloud_run_v2_service.lab4.name
}
