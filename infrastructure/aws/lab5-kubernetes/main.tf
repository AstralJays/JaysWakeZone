# Stack 3 of 3 — EKS + WakeBot + in-cluster Ollama on GPU (Lab 5)
# Publish YOURUSER/jwz-agent-lab then set container_image.
# 1× t3.large (app + Upwind headroom) + 1× g4dn.xlarge (Ollama/T4) — destroy promptly (GPU $).
# Node RAM sized for Upwind Sensor (≥4 GiB recommended) + Cluster Manager (~2 GiB) — SA installs Upwind.

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
  description = "Docker Hub image you published from lab5-agentic/"
  default     = "YOURUSER/jwz-agent-lab:0.1.0"
}

variable "ollama_model" {
  type        = string
  description = "Model pulled into in-cluster Ollama"
  default     = "llama3.2"
}

variable "gpu_instance_type" {
  type        = string
  description = "GPU node for Ollama (T4-class)"
  default     = "g4dn.xlarge"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null
}

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

# WakeBot + room for Upwind operator / cluster-manager / sensor (SA installs)
# t3.large = 2 vCPU / 8 GiB — meets Upwind's ≥4 GiB node guidance with headroom
resource "aws_eks_node_group" "cpu" {
  cluster_name    = aws_eks_cluster.lab5.name
  node_group_name = "jwz-cpu"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.public[*].id
  instance_types  = ["t3.large"]
  capacity_type   = "ON_DEMAND"
  disk_size       = 40

  labels = {
    workload = "cpu"
  }

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

# Ollama — T4 GPU (needs GPU AMI + nvidia device plugin)
resource "aws_eks_node_group" "gpu" {
  cluster_name    = aws_eks_cluster.lab5.name
  node_group_name = "jwz-gpu"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.public[*].id
  instance_types  = [var.gpu_instance_type]
  ami_type        = "AL2_x86_64_GPU"
  capacity_type   = "ON_DEMAND"
  disk_size       = 100

  labels = {
    workload = "gpu"
  }

  taint {
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

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

resource "kubernetes_daemon_set_v1" "nvidia_device_plugin" {
  metadata {
    name      = "nvidia-device-plugin-daemonset"
    namespace = "kube-system"
    labels    = { name = "nvidia-device-plugin-ds" }
  }

  spec {
    selector {
      match_labels = { name = "nvidia-device-plugin-ds" }
    }
    strategy {
      type = "RollingUpdate"
    }
    template {
      metadata {
        labels = { name = "nvidia-device-plugin-ds" }
      }
      spec {
        toleration {
          key      = "nvidia.com/gpu"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        priority_class_name = "system-node-critical"
        container {
          image = "nvcr.io/nvidia/k8s-device-plugin:v0.14.5"
          name  = "nvidia-device-plugin-ctr"
          env {
            name  = "FAIL_ON_INIT_ERROR"
            value = "false"
          }
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }
          volume_mount {
            name       = "device-plugin"
            mount_path = "/var/lib/kubelet/device-plugins"
          }
        }
        volume {
          name = "device-plugin"
          host_path {
            path = "/var/lib/kubelet/device-plugins"
          }
        }
      }
    }
  }

  depends_on = [aws_eks_node_group.gpu]
}

resource "kubernetes_deployment" "ollama" {
  metadata {
    name   = "ollama"
    labels = { app = "ollama", lab = "5" }
  }

  wait_for_rollout = false

  spec {
    replicas = 1
    selector {
      match_labels = { app = "ollama" }
    }
    template {
      metadata {
        labels = { app = "ollama" }
      }
      spec {
        node_selector = {
          workload = "gpu"
        }
        toleration {
          key      = "nvidia.com/gpu"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }
        container {
          name  = "ollama"
          image = "ollama/ollama:latest"

          port {
            name           = "http"
            container_port = 11434
          }

          # Leave RAM for Upwind Sensor DaemonSet on the GPU node (do not max the node)
          resources {
            requests = {
              cpu              = "1"
              memory           = "2Gi"
              "nvidia.com/gpu" = "1"
            }
            limits = {
              cpu              = "2"
              memory           = "6Gi"
              "nvidia.com/gpu" = "1"
            }
          }

          volume_mount {
            name       = "ollama-data"
            mount_path = "/root/.ollama"
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 11434
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }
        }
        volume {
          name = "ollama-data"
          empty_dir {}
        }
      }
    }
  }

  depends_on = [
    aws_eks_node_group.gpu,
    kubernetes_daemon_set_v1.nvidia_device_plugin,
  ]
}

resource "kubernetes_service" "ollama" {
  metadata {
    name = "ollama"
  }
  spec {
    selector = { app = "ollama" }
    port {
      name        = "http"
      port        = 11434
      target_port = 11434
    }
  }

  depends_on = [kubernetes_deployment.ollama]
}

resource "kubernetes_job_v1" "ollama_pull" {
  metadata {
    name = "ollama-pull-model"
  }

  wait_for_completion = false

  spec {
    backoff_limit = 8
    template {
      metadata {
        labels = { app = "ollama-pull" }
      }
      spec {
        restart_policy = "OnFailure"
        container {
          name  = "pull"
          image = "ollama/ollama:latest"
          env {
            name  = "OLLAMA_HOST"
            value = "http://ollama:11434"
          }
          command = ["ollama", "pull", var.ollama_model]
        }
      }
    }
  }

  depends_on = [kubernetes_service.ollama]
}

resource "kubernetes_deployment" "jwz" {
  metadata {
    name   = "jwz-agent-lab"
    labels = { app = "jwz-agent-lab", lab = "5" }
  }

  spec {
    replicas = 1
    selector {
      match_labels = { app = "jwz-agent-lab" }
    }
    template {
      metadata {
        labels = { app = "jwz-agent-lab" }
      }
      spec {
        node_selector = {
          workload = "cpu"
        }
        container {
          name              = "app"
          image             = var.container_image
          image_pull_policy = "IfNotPresent"

          env {
            name  = "PORT"
            value = "8080"
          }
          env {
            name  = "OLLAMA_BASE_URL"
            value = "http://ollama.default.svc.cluster.local:11434/v1"
          }
          env {
            name  = "OLLAMA_MODEL"
            value = var.ollama_model
          }

          port {
            name           = "http"
            container_port = 8080
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 8
            period_seconds        = 10
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [
    aws_eks_node_group.cpu,
    kubernetes_service.ollama,
  ]
}

resource "kubernetes_service" "jwz" {
  metadata {
    name = "jwz-agent-lab"
  }
  spec {
    type     = "LoadBalancer"
    selector = { app = "jwz-agent-lab" }
    port {
      name        = "http"
      port        = 80
      target_port = 8080
    }
  }

  depends_on = [kubernetes_deployment.jwz]
}

output "lab5_cluster_name" {
  value = aws_eks_cluster.lab5.name
}

output "lab5_url" {
  description = "WakeBot UI — install cluster sensor yourself"
  value       = try("http://${kubernetes_service.jwz.status[0].load_balancer[0].ingress[0].hostname}", "pending-lb")
}

output "lab5_ollama" {
  value = "in-cluster Service ollama:11434 (GPU) · model ${var.ollama_model}"
}

output "lab5_kubeconfig_hint" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.lab5.name}"
}
