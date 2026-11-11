terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type        = string
  default     = ""
  description = "Optional AWS shared-config profile. Empty = default credential chain."
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

variable "instance_type" {
  type    = string
  default = "t3.large"
}

variable "root_volume_gb" {
  type    = number
  default = 40
}

variable "ssh_ingress_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "app_ingress_cidr" {
  type    = string
  default = "0.0.0.0/0"
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

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null
}

data "aws_caller_identity" "current" {}

data "aws_ami" "ubuntu" {
  count       = var.enable_lab2 ? 1 : 0
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
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

# ---------------------------------------------------------------------------
# Lab 1 — intentionally public S3 with synthetic PII
# ---------------------------------------------------------------------------

resource "aws_s3_account_public_access_block" "demo" {
  count                   = var.enable_lab1 ? 1 : 0
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket" "lab1" {
  count         = var.enable_lab1 ? 1 : 0
  bucket        = "${var.name_prefix}-pii-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name        = "${var.name_prefix}-public-pii"
    Project     = "JaysWakeZone"
    Lab         = "1"
    DemoFinding = "public-s3-bucket"
    CSPMCheck   = "s3-bucket-public-read"
    DataClass   = "synthetic-pii"
  }
}

resource "aws_s3_bucket_public_access_block" "lab1" {
  count  = var.enable_lab1 ? 1 : 0
  bucket = aws_s3_bucket.lab1[0].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "lab1_public_read" {
  count  = var.enable_lab1 ? 1 : 0
  bucket = aws_s3_bucket.lab1[0].id

  depends_on = [
    aws_s3_account_public_access_block.demo,
    aws_s3_bucket_public_access_block.lab1,
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.lab1[0].arn}/*"
      },
      {
        Sid       = "PublicListBucket"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:ListBucket"
        Resource  = aws_s3_bucket.lab1[0].arn
      },
    ]
  })
}

resource "aws_s3_object" "lab1_objects" {
  for_each = var.enable_lab1 ? local.lab1_objects : {}

  bucket       = aws_s3_bucket.lab1[0].id
  key          = each.key
  source       = "${local.data_dir}/${each.value.file}"
  content_type = each.value.content_type
  etag         = filemd5("${local.data_dir}/${each.value.file}")
}

# ---------------------------------------------------------------------------
# Lab 2 — DVWA-lite on EC2 (Docker)
# ---------------------------------------------------------------------------

resource "aws_security_group" "lab2" {
  count       = var.enable_lab2 ? 1 : 0
  name_prefix = "${var.name_prefix}-"
  description = "JaysWakeZone Lab 2 HTTP + SSH"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  ingress {
    description = "App"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.app_ingress_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-lab2-sg" }
}

locals {
  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    export REPO_URL='${var.repo_url}'
    export REPO_REF='${var.repo_ref}'
    export UPWIND_CLIENT_ID='${var.upwind_client_id}'
    export UPWIND_CLIENT_SECRET='${var.upwind_client_secret}'
    export UPWIND_AGENT_EXTRA_CONFIG='${var.upwind_agent_extra_config}'

    apt-get update -y && apt-get install -y git curl ca-certificates
    git clone --depth 1 --branch "$REPO_REF" "$REPO_URL" /tmp/jwz
    chmod +x /tmp/jwz/scripts/install-app.sh /tmp/jwz/scripts/install-upwind-sensor.sh
    /tmp/jwz/scripts/install-upwind-sensor.sh || true
    /tmp/jwz/scripts/install-app.sh
  EOF
}

resource "aws_instance" "lab2" {
  count                       = var.enable_lab2 ? 1 : 0
  ami                         = data.aws_ami.ubuntu[0].id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.lab2[0].id]
  user_data                   = local.user_data
  user_data_replace_on_change = true

  root_block_device {
    volume_size           = var.root_volume_gb
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name    = "${var.name_prefix}-lab2"
    Project = "JaysWakeZone"
    Lab     = "2"
  }
}

output "lab1_bucket_name" {
  value = var.enable_lab1 ? aws_s3_bucket.lab1[0].id : null
}

output "lab1_public_url" {
  value = var.enable_lab1 ? "https://${aws_s3_bucket.lab1[0].bucket}.s3.${var.aws_region}.amazonaws.com/exports/customers.json" : null
}

output "lab1_list_hint" {
  value = var.enable_lab1 ? "aws s3 ls s3://${aws_s3_bucket.lab1[0].id}/ --no-sign-request" : null
}

output "lab2_application_url" {
  value = var.enable_lab2 ? "http://${aws_instance.lab2[0].public_ip}:8080/labs" : null
}

output "lab2_public_ip" {
  value = var.enable_lab2 ? aws_instance.lab2[0].public_ip : null
}
