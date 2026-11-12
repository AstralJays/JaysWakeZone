# Stack 1 of 3 — Labs 1–3 (Storage + VM and Hosts + Serverless)
# Independent of containers/ and kubernetes/. Destroy this stack without touching those.

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

variable "serverless_image" {
  type        = string
  default     = "docker.io/library/python:3.9-bullseye"
  description = "Public Docker Hub image — no build/push."
}

variable "repo_url" {
  type    = string
  default = "https://github.com/AstralJays/JaysWakeZone.git"
}

variable "repo_ref" {
  type    = string
  default = "main"
}

data "google_project" "current" {}

locals {
  data_dir = "${path.module}/../../../lab1-public-data"
  lab1_objects = {
    "exports/name-ssn-ccn.csv"   = { file = "name-ssn-ccn.csv", content_type = "text/csv" }
    "exports/name-ssn-dob.csv"   = { file = "name-ssn-dob.csv", content_type = "text/csv" }
    "exports/name-ccn-zip.csv"   = { file = "name-ccn-zip.csv", content_type = "text/csv" }
    "exports/name-dob-email.csv" = { file = "name-dob-email.csv", content_type = "text/csv" }
    "exports/customers.json"     = { file = "customers.json", content_type = "application/json" }
  }
  lab1_buckets = {
    remediate = { suffix = "remediate", cspm_loop = "remediate" }
    exception = { suffix = "exception", cspm_loop = "risk-accept" }
  }
  lab1_object_keys = {
    for pair in setproduct(keys(local.lab1_buckets), keys(local.lab1_objects)) :
    "${pair[0]}|${pair[1]}" => {
      bucket_key   = pair[0]
      object_key   = pair[1]
      file         = local.lab1_objects[pair[1]].file
      content_type = local.lab1_objects[pair[1]].content_type
    }
  }
  startup   = <<-EOF
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
  lab3_boot = <<-BOOT
    set -e
    pip install --no-cache-dir flask==2.0.3 werkzeug==2.0.3
    cat >/tmp/jwz_app.py <<'PY'
    from flask import Flask
    app = Flask(__name__)
    @app.route("/")
    def index():
        return {"status": "running", "demo": "cve-detection", "lab": "3-serverless"}
    @app.route("/health")
    def health():
        return {"ok": True}
    app.run(host="0.0.0.0", port=8080)
    PY
    exec python /tmp/jwz_app.py
  BOOT
}

# --- Lab 1 ---

resource "google_storage_bucket" "lab1" {
  for_each      = local.lab1_buckets
  name          = "${var.name_prefix}-${each.value.suffix}-${data.google_project.current.number}"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  labels = {
    project      = "jayswakezone"
    stack        = "lab1-3"
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
  for_each     = local.lab1_object_keys
  name         = each.value.object_key
  bucket       = google_storage_bucket.lab1[each.value.bucket_key].name
  source       = "${local.data_dir}/${each.value.file}"
  content_type = each.value.content_type
}

# --- Lab 2 — VM and Hosts ---

resource "google_compute_network" "main" {
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name          = "${var.name_prefix}-subnet"
  ip_cidr_range = "10.50.0.0/24"
  region        = var.region
  network       = google_compute_network.main.id
}

resource "google_compute_firewall" "lab2" {
  name    = "${var.name_prefix}-allow-app"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22", "8080", "10000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["jayswakezone"]
}

resource "google_compute_instance" "lab2" {
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
    subnetwork = google_compute_subnetwork.main.id
    access_config {}
  }

  metadata_startup_script = local.startup

  labels = {
    project = "jayswakezone"
    stack   = "lab1-3"
    lab     = "2"
    track   = "vm-and-hosts"
  }
}

# --- Lab 3 — Cloud Run ---

resource "google_cloud_run_v2_service" "lab3" {
  name     = "${var.name_prefix}-lab3"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image   = var.serverless_image
      command = ["bash", "-c"]
      args    = [local.lab3_boot]
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
    stack   = "lab1-3"
    lab     = "3"
  }
}

resource "google_cloud_run_v2_service_iam_member" "lab3_public" {
  project  = var.project_id
  location = google_cloud_run_v2_service.lab3.location
  name     = google_cloud_run_v2_service.lab3.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "lab1_remediate_bucket" {
  description = "Fix this one (remove public IAM → reassess clear)"
  value       = google_storage_bucket.lab1["remediate"].name
}

output "lab1_remediate_url" {
  value = "https://storage.googleapis.com/${google_storage_bucket.lab1["remediate"].name}/exports/customers.json"
}

output "lab1_exception_bucket" {
  description = "Leave public; whitelist / accept risk"
  value       = google_storage_bucket.lab1["exception"].name
}

output "lab1_exception_url" {
  value = "https://storage.googleapis.com/${google_storage_bucket.lab1["exception"].name}/exports/customers.json"
}

output "lab2_application_url" {
  value = "http://${google_compute_instance.lab2.network_interface[0].access_config[0].nat_ip}:8080/labs"
}

output "lab2_webmin_url" {
  value = "https://${google_compute_instance.lab2.network_interface[0].access_config[0].nat_ip}:10000"
}

output "lab2_webmin_credentials" {
  value = "admin / password"
}

output "lab2_public_ip" {
  value = google_compute_instance.lab2.network_interface[0].access_config[0].nat_ip
}

output "lab3_service_name" {
  value = google_cloud_run_v2_service.lab3.name
}

output "lab3_service_url" {
  description = "Cloud Run URL — SA installs tracer themselves"
  value       = google_cloud_run_v2_service.lab3.uri
}
