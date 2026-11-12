# Stack 3 of 3 — EKS + Damn Vulnerable AI Agent (Lab 5)
# 1× t3.medium node — destroy promptly (control plane + node hours).
# Image: public Docker Hub opena2a/dvaa (no private registry / no build).

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = ""
}

variable "name_prefix" {
  type    = string
  default = "jayswakezone"
}

variable "container_image" {
  type        = string
  description = "Public DVAA image — https://hub.docker.com/r/opena2a/dvaa"
  default     = "opena2a/dvaa:0.9.2"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "k8s" {
  cidr_block           = "10.60.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${var.name_prefix}-eks-vpc", Lab = "5" }
}

resource "aws_internet_gateway" "k8s" {
  vpc_id = aws_vpc.k8s.id
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.k8s.id
  cidr_block              = cidrsubnet(aws_vpc.k8s.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name                     = "${var.name_prefix}-eks-public-${count.index}"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.k8s.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_iam_role" "cluster" {
  name = "${var.name_prefix}-eks-cluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "lab5" {
  name     = "${var.name_prefix}-lab5"
  role_arn = aws_iam_role.cluster.arn
  version  = "1.29"

  vpc_config {
    subnet_ids              = aws_subnet.public[*].id
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]

  tags = {
    Project = "JaysWakeZone"
    Stack   = "lab5-kubernetes"
    Lab     = "5"
  }
}

resource "aws_iam_role" "node" {
  name = "${var.name_prefix}-eks-node"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "lab5" {
  cluster_name    = aws_eks_cluster.lab5.name
  node_group_name = "jwz"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.public[*].id
  # DVAA runs ~19 agents — 2 GiB nodes OOMs; t3.medium ≈ 4 GiB
  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]
}

data "aws_eks_cluster_auth" "lab5" {
  name = aws_eks_cluster.lab5.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.lab5.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.lab5.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.lab5.token
}

resource "kubernetes_deployment" "jwz" {
  metadata {
    name = "jwz-dvaa"
    labels = {
      app = "jwz-dvaa"
      lab = "5"
    }
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

  depends_on = [aws_eks_node_group.lab5]
}

# Dashboard only on the LB — agent ports stay in-cluster (port-forward for HMA).
resource "kubernetes_service" "jwz" {
  metadata {
    name = "jwz-dvaa"
  }
  spec {
    type = "LoadBalancer"
    selector = {
      app = "jwz-dvaa"
    }
    port {
      name        = "dashboard"
      port        = 80
      target_port = 9000
    }
  }

  depends_on = [kubernetes_deployment.jwz]
}

output "lab5_cluster_name" {
  value = aws_eks_cluster.lab5.name
}

output "lab5_url" {
  description = "DVAA dashboard (intentionally vulnerable — lab only). Install cluster sensor yourself."
  value       = try("http://${kubernetes_service.jwz.status[0].load_balancer[0].ingress[0].hostname}", "pending-lb")
}

output "lab5_kubeconfig_hint" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.lab5.name}"
}

output "lab5_port_forward_agents" {
  description = "Forward agent ports for HackMyAgent / curl against the fleet"
  value       = "kubectl port-forward deploy/jwz-dvaa 9000:9000 7003:7003"
}
