terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
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

# Labs 1 + 2 + 3 ship together by default. Lab 4 (K8s) last / later.
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
  default     = true
  description = "Lambda zip + Function URL (no ECR)."
}

variable "enable_lab4" {
  type        = bool
  default     = false
  description = "Planned — EKS. Keep false until lab4-kubernetes lands."
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
  # Two buckets = full CSPM loop without re-breaking: remediate one, risk-accept the other.
  lab1_buckets = var.enable_lab1 ? {
    remediate = {
      suffix    = "remediate"
      cspm_loop = "remediate"
    }
    exception = {
      suffix    = "exception"
      cspm_loop = "risk-accept"
    }
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

# ---------------------------------------------------------------------------
# Lab 1 — two public S3 buckets + synthetic PII (remediate + risk-accept)
# ---------------------------------------------------------------------------

resource "aws_s3_account_public_access_block" "demo" {
  count                   = var.enable_lab1 ? 1 : 0
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket" "lab1" {
  for_each      = local.lab1_buckets
  bucket        = "${var.name_prefix}-${each.value.suffix}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name        = "${var.name_prefix}-${each.value.suffix}"
    Project     = "JaysWakeZone"
    Lab         = "1"
    CspmLoop    = each.value.cspm_loop
    DemoFinding = "public-s3-bucket"
    CSPMCheck   = "s3-bucket-public-read"
    DataClass   = "synthetic-pii"
  }
}

resource "aws_s3_bucket_public_access_block" "lab1" {
  for_each = local.lab1_buckets
  bucket   = aws_s3_bucket.lab1[each.key].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "lab1_public_read" {
  for_each = local.lab1_buckets
  bucket   = aws_s3_bucket.lab1[each.key].id

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
        Resource  = "${aws_s3_bucket.lab1[each.key].arn}/*"
      },
      {
        Sid       = "PublicListBucket"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:ListBucket"
        Resource  = aws_s3_bucket.lab1[each.key].arn
      },
    ]
  })
}

resource "aws_s3_object" "lab1_objects" {
  for_each = local.lab1_object_keys

  bucket       = aws_s3_bucket.lab1[each.value.bucket_key].id
  key          = each.value.object_key
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
  description = "JaysWakeZone Lab 2 VM and Hosts — HTTP + SSH"

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

  ingress {
    description = "Webmin (intentional exposure — admin/password)"
    from_port   = 10000
    to_port     = 10000
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

    apt-get update -y && apt-get install -y git curl ca-certificates
    git clone --depth 1 --branch "$REPO_REF" "$REPO_URL" /tmp/jwz
    chmod +x /tmp/jwz/scripts/install-app.sh
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
    Track   = "VM-and-Hosts"
  }
}

output "lab1_remediate_bucket" {
  description = "Fix this one (block public → reassess clear)"
  value       = var.enable_lab1 ? aws_s3_bucket.lab1["remediate"].id : null
}

output "lab1_remediate_url" {
  value = var.enable_lab1 ? "https://${aws_s3_bucket.lab1["remediate"].bucket}.s3.${var.aws_region}.amazonaws.com/exports/customers.json" : null
}

output "lab1_exception_bucket" {
  description = "Leave public; whitelist / accept risk"
  value       = var.enable_lab1 ? aws_s3_bucket.lab1["exception"].id : null
}

output "lab1_exception_url" {
  value = var.enable_lab1 ? "https://${aws_s3_bucket.lab1["exception"].bucket}.s3.${var.aws_region}.amazonaws.com/exports/customers.json" : null
}

output "lab1_list_hint" {
  value = var.enable_lab1 ? "aws s3 ls s3://${aws_s3_bucket.lab1["remediate"].id}/ --no-sign-request" : null
}

output "lab2_application_url" {
  value = var.enable_lab2 ? "http://${aws_instance.lab2[0].public_ip}:8080/labs" : null
}

output "lab2_webmin_url" {
  value = var.enable_lab2 ? "https://${aws_instance.lab2[0].public_ip}:10000" : null
}

output "lab2_webmin_credentials" {
  value = var.enable_lab2 ? "admin / password" : null
}

output "lab2_public_ip" {
  value = var.enable_lab2 ? aws_instance.lab2[0].public_ip : null
}

# ---------------------------------------------------------------------------
# Lab 3 — Lambda zip + Function URL (no ECR / no Docker build)
# ---------------------------------------------------------------------------

data "archive_file" "lab3" {
  count       = var.enable_lab3 ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/../../lab3-serverless/lambda/handler.py"
  output_path = "${path.module}/.build/lab3-lambda.zip"
}

resource "aws_iam_role" "lab3" {
  count = var.enable_lab3 ? 1 : 0
  name  = "${var.name_prefix}-lab3-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = {
    Project = "JaysWakeZone"
    Lab     = "3"
  }
}

resource "aws_iam_role_policy_attachment" "lab3_basic" {
  count      = var.enable_lab3 ? 1 : 0
  role       = aws_iam_role.lab3[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lab3" {
  count            = var.enable_lab3 ? 1 : 0
  function_name    = "${var.name_prefix}-lab3"
  role             = aws_iam_role.lab3[0].arn
  handler          = "handler.handler"
  runtime          = "python3.9"
  filename         = data.archive_file.lab3[0].output_path
  source_code_hash = data.archive_file.lab3[0].output_base64sha256
  timeout          = 10
  memory_size      = 128

  tags = {
    Project = "JaysWakeZone"
    Lab     = "3"
    Demo    = "serverless-tracer-candidate"
  }
}

resource "aws_lambda_function_url" "lab3" {
  count              = var.enable_lab3 ? 1 : 0
  function_name      = aws_lambda_function.lab3[0].function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "lab3_url" {
  count                  = var.enable_lab3 ? 1 : 0
  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.lab3[0].function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

output "lab3_function_name" {
  value = var.enable_lab3 ? aws_lambda_function.lab3[0].function_name : null
}

output "lab3_function_url" {
  description = "Public Lambda Function URL — SA installs tracer themselves"
  value       = var.enable_lab3 ? aws_lambda_function_url.lab3[0].function_url : null
}
