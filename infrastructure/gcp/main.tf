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

# Labs 1 + 2 + 4 ship together by default (one terraform apply). Lab 3 (K8s) later.
variable "enable_lab1" {
  type    = bool
  default = true
}

variable "enable_lab2" {
  type    = bool
  default = true
}

variable "enable_lab3" {
  type        = bool
  default     = false
  description = "Planned — GKE. Keep false until lab3-kubernetes lands."
}

variable "enable_lab4" {
  type        = bool
  default     = true
  description = "Cloud Run from public GHCR image (no GAR)."
}

variable "serverless_image" {
  type        = string
  default     = "ghcr.io/astraljays/jayswakezone-flask:3.9-bullseye"
  description = "Public container image. Built by GitHub Actions — no GAR push."
}

variable "repo_url" {
  type    = string
  default = "https://github.com/AstralJays/JaysWakeZone.git"
}

variable "repo_ref" {
  type    = string
  default = "main"
}

locals {
  data_dir = "${path.module}/../../lab1-public-data"
  lab1_objects = {
    "exports/name-ssn-ccn.csv"   = { file = "name-ssn-ccn.csv", content_type = "text/csv" }
    "exports/name-ssn-dob.csv"   = { file = "name-ssn-dob.csv", content_type = "text/csv" }
    "exports/name-ccn-zip.csv"   = { file = "name-ccn-zip.csv", content_type = "text/csv" }
    "exports/name-dob-email.csv" = { file = "name-dob-email.csv", content_type = "text/csv" }
    "exports/customers.json"     = { file = "customers.json", content_type = "application/json" }
  }
  # Two buckets = full CSPM loop without re-breaking: remediate one, risk-accept the other.
  lab1_buckets = var.enable_lab1 ? {
    remediate = { suffix = "remediate", cspm_loop = "remediate" }
    exception = { suffix = "exception", cspm_loop = "risk-accept" }
  } : {}
  lab1_object_keys = {
    for pair in setproduct(keys(local.lab1_buckets), keys(local.lab1_objects)) :
    "${pair[0]}|${pair[1]}" => {
      bucket_key   = pair[0]
      object_key   = pair[1]
      file         = local.lab1_objects[pair[1]].file
      content_type = local.lab1_objects[pair[1]].content_type
    }
  }
}

data "google_project" "current" {}

# ---------------------------------------------------------------------------
# Lab 1 — two public GCS buckets + synthetic PII (remediate + risk-accept)
# ---------------------------------------------------------------------------

resource "google_storage_bucket" "lab1" {
  for_each      = local.lab1_buckets
  name          = "${var.name_prefix}-${each.value.suffix}-${data.google_project.current.number}"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  labels = {
    project      = "jayswakezone"
    lab          = "1"
    cspm_loop    = each.value.cspm_loop
    demo_finding = "public-gcs-bucket"
    dataclass    = "synthetic-pii"
  }
}

resource "google_storage_bucket_iam_member" "lab1_public" {
  for_each = local.lab1_buckets
  bucket   = google_storage_bucket.lab1[each.key].name
  role     = "roles/storage.objectViewer"
  member   = "allUsers"
}

resource "google_storage_bucket_object" "lab1_objects" {
  for_each = local.lab1_object_keys

  name         = each.value.object_key
  bucket       = google_storage_bucket.lab1[each.value.bucket_key].name
  source       = "${local.data_dir}/${each.value.file}"
  content_type = each.value.content_type
}

# ---------------------------------------------------------------------------
# Lab 2 — DVWA-lite on GCE (Docker)
# ---------------------------------------------------------------------------

resource "google_compute_network" "main" {
  count                   = var.enable_lab2 ? 1 : 0
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  count         = var.enable_lab2 ? 1 : 0
  name          = "${var.name_prefix}-subnet"
  ip_cidr_range = "10.50.0.0/24"
  region        = var.region
  network       = google_compute_network.main[0].id
}

resource "google_compute_firewall" "lab2" {
  count   = var.enable_lab2 ? 1 : 0
  name    = "${var.name_prefix}-allow-app"
  network = google_compute_network.main[0].name

  allow {
    protocol = "tcp"
    ports    = ["22", "8080", "10000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["jayswakezone"]
}

locals {
  startup = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    export REPO_URL='${var.repo_url}'
    export REPO_REF='${var.repo_ref}'
    apt-get update -y
    apt-get install -y git curl ca-certificates
    git clone --depth 1 --branch "${var.repo_ref}" "${var.repo_url}" /tmp/jwz
    chmod +x /tmp/jwz/scripts/install-app.sh
    /tmp/jwz/scripts/install-app.sh
  EOF
}

resource "google_compute_instance" "lab2" {
  count        = var.enable_lab2 ? 1 : 0
  name         = "${var.name_prefix}-lab2"
  machine_type = "e2-standard-2"
  zone         = var.zone
  tags         = ["jayswakezone"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 40
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main[0].id
    access_config {}
  }

  metadata_startup_script = local.startup

  labels = {
    project = "jayswakezone"
    lab     = "2"
  }
}

output "lab1_remediate_bucket" {
  description = "Fix this one (remove public IAM → reassess clear)"
  value       = var.enable_lab1 ? google_storage_bucket.lab1["remediate"].name : null
}

output "lab1_remediate_url" {
  value = var.enable_lab1 ? "https://storage.googleapis.com/${google_storage_bucket.lab1["remediate"].name}/exports/customers.json" : null
}

output "lab1_exception_bucket" {
  description = "Leave public; whitelist / accept risk"
  value       = var.enable_lab1 ? google_storage_bucket.lab1["exception"].name : null
}

output "lab1_exception_url" {
  value = var.enable_lab1 ? "https://storage.googleapis.com/${google_storage_bucket.lab1["exception"].name}/exports/customers.json" : null
}

output "lab2_application_url" {
  value = var.enable_lab2 ? "http://${google_compute_instance.lab2[0].network_interface[0].access_config[0].nat_ip}:8080/labs" : null
}

output "lab2_webmin_url" {
  value = var.enable_lab2 ? "https://${google_compute_instance.lab2[0].network_interface[0].access_config[0].nat_ip}:10000" : null
}

output "lab2_webmin_credentials" {
  value = var.enable_lab2 ? "admin / password" : null
}

output "lab2_public_ip" {
  value = var.enable_lab2 ? google_compute_instance.lab2[0].network_interface[0].access_config[0].nat_ip : null
}

# ---------------------------------------------------------------------------
# Lab 4 — Cloud Run from public GHCR image (no GAR build/push)
# ---------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "lab4" {
  count    = var.enable_lab4 ? 1 : 0
  name     = "${var.name_prefix}-lab4"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = var.serverless_image
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
    lab     = "4"
  }
}

resource "google_cloud_run_v2_service_iam_member" "lab4_public" {
  count    = var.enable_lab4 ? 1 : 0
  project  = var.project_id
  location = google_cloud_run_v2_service.lab4[0].location
  name     = google_cloud_run_v2_service.lab4[0].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "lab4_service_name" {
  value = var.enable_lab4 ? google_cloud_run_v2_service.lab4[0].name : null
}

output "lab4_service_url" {
  description = "Cloud Run URL — SA installs tracer themselves"
  value       = var.enable_lab4 ? google_cloud_run_v2_service.lab4[0].uri : null
}
