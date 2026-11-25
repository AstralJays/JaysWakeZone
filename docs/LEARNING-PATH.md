# JaysWakeZone ↔ SA Surf School

Three top-level lab folders; each has `infrastructure/{aws|azure|gcp}/`:

| Folder | Labs | Platforms |
|--------|------|-----------|
| `Lab1-3/` | 1 Storage · 2 VM/Hosts · 3 Serverless | buckets · VM · Lambda/App Service/Cloud Run |
| `Lab4/` | 4 Juice Shop (public image) | ECS Fargate · ACA · Cloud Run |
| `Lab5/` | 5 Wakezone AI (`papaperk/jwz-agent-lab`) + Ollama GPU | EKS · AKS · GKE |

## Apps

| Lab | Code |
|-----|------|
| 1 | `Lab1-3/lab1-public-data/` |
| 2 | `Lab1-3/lab2-hosts-vms/` |
| 3 | `Lab1-3/lab3-serverless/` |
| 4 | `Lab4/` (Juice Shop) |
| 5 | `Lab5/` (public Hub image) → K8s |

SA installs sensors/tracers — not in Terraform.

## Cost

Day-1 = `Lab1-3/` only. Lab 5 destroy promptly.
