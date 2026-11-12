# JaysWakeZone ↔ SA Surf School

Three **independent** Terraform stacks per cloud. Apps are wired for all five labs.

| Stack | Dir | Labs | Platforms |
|-------|-----|------|-----------|
| 1 | `labs-1-3/` | 1 Storage · 2 VM and Hosts · 3 Serverless | S3/Blob/GCS · EC2/Azure VM/GCE · Lambda/App Service/Cloud Run |
| 2 | `containers/` | 4 Managed containers | ECS Fargate · ACA · Cloud Run |
| 3 | `kubernetes/` | 5 Kubernetes | EKS · AKS · GKE |

## Apps

| Lab | Code |
|-----|------|
| 1 | `lab1-public-data/` |
| 2 | `lab2-wakezone-app/` |
| 3 | `lab3-serverless/` |
| 4 | `lab4-containers/` (Flask on public bullseye) |
| 5 | `lab5-kubernetes/` (+ `manifests/`) |

SA installs sensors/tracers — never baked into Terraform.

## Cost

Day-1 = stack 1. Stacks 2–3 opt-in; destroy K8s promptly.
