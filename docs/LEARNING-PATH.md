# JaysWakeZone ↔ SA Surf School

Per cloud, **three Terraform folders** that match lab numbers:

| Folder | Labs | Platforms |
|--------|------|-----------|
| `infrastructure/<cloud>/lab1-3/` | 1 Storage · 2 VM and Hosts · 3 Serverless | buckets · VM · Lambda/App Service/Cloud Run |
| `infrastructure/<cloud>/lab4-containers/` | 4 Juice Shop (public image) | ECS Fargate · ACA · Cloud Run |
| `infrastructure/<cloud>/lab5-kubernetes/` | 5 Kubernetes | EKS · AKS · GKE |

## Apps

| Lab | Code |
|-----|------|
| 1 | `lab1-public-data/` |
| 2 | `lab2-hosts-vms/` |
| 3 | `lab3-serverless/` |
| 4 | `lab4-containers/` (Juice Shop) |
| 5 | `lab5-kubernetes/` |

SA installs sensors/tracers — not in Terraform.

## Cost

Day-1 = `lab1-3/` only. Lab 5 destroy promptly.
