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

variable "enable_lab1" {
  type    = bool
  default = true
}

variable "enable_lab2" {
  type    = bool
  default = true
}

variable "repo_url" {
  type    = string
  default = "https://github.com/AstralJays/JaysWakeZone.git"
}

variable "repo_ref" {
  type    = string
  default = "main"
}

variable "upwind_client_id" {
  type      = string
  default   = ""
  sensitive = true
}

variable "upwind_client_secret" {
  type      = string
  default   = ""
  sensitive = true
}

variable "upwind_agent_extra_config" {
  type    = string
  default = "scanner-v2=true"
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
}

data "google_project" "current" {}

# ---------------------------------------------------------------------------
# Lab 1 — public GCS bucket with synthetic PII
# ---------------------------------------------------------------------------

resource "google_storage_bucket" "lab1" {
  count         = var.enable_lab1 ? 1 : 0
  name          = "${var.name_prefix}-pii-${data.google_project.current.number}"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  labels = {
    project     = "jayswakezone"
    lab         = "1"
    demo_finding = "public-gcs-bucket"
    dataclass   = "synthetic-pii"
  }
}

resource "google_storage_bucket_iam_member" "lab1_public" {
  count  = var.enable_lab1 ? 1 : 0
  bucket = google_storage_bucket.lab1[0].name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_storage_bucket_object" "lab1_objects" {
  for_each = var.enable_lab1 ? local.lab1_objects : {}

  name         = each.key
  bucket       = google_storage_bucket.lab1[0].name
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
    ports    = ["22", "8080"]
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
    export UPWIND_CLIENT_ID='${var.upwind_client_id}'
    export UPWIND_CLIENT_SECRET='${var.upwind_client_secret}'
    export UPWIND_AGENT_EXTRA_CONFIG='${var.upwind_agent_extra_config}'
    apt-get update -y
    apt-get install -y git curl ca-certificates
    git clone --depth 1 --branch "${var.repo_ref}" "${var.repo_url}" /tmp/jwz
    chmod +x /tmp/jwz/scripts/install-app.sh /tmp/jwz/scripts/install-upwind-sensor.sh
    /tmp/jwz/scripts/install-upwind-sensor.sh || true
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

output "lab1_bucket_name" {
  value = var.enable_lab1 ? google_storage_bucket.lab1[0].name : null
}

output "lab1_public_url" {
  value = var.enable_lab1 ? "https://storage.googleapis.com/${google_storage_bucket.lab1[0].name}/exports/customers.json" : null
}

output "lab2_application_url" {
  value = var.enable_lab2 ? "http://${google_compute_instance.lab2[0].network_interface[0].access_config[0].nat_ip}:8080/labs" : null
}

output "lab2_public_ip" {
  value = var.enable_lab2 ? google_compute_instance.lab2[0].network_interface[0].access_config[0].nat_ip : null
}
