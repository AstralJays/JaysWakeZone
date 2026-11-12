# Lab 4 — Managed containers (OWASP Juice Shop)

**No image build/push.** Terraform pulls the public Docker Hub image and runs it.

| | |
|-|-|
| **Image** | `bkimminich/juice-shop:latest` |
| **Port** | `3000` |
| **You install** | Upwind tracer (after apply) |

| Cloud | Path | Platform |
|-------|------|----------|
| AWS | `infrastructure/aws/lab4-containers/` | ECS Fargate + ALB |
| Azure | `infrastructure/azure/lab4-containers/` | Azure Container Apps |
| GCP | `infrastructure/gcp/lab4-containers/` | Cloud Run |

```bash
cd infrastructure/aws/lab4-containers   # or azure|gcp
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output lab4_url
```

Open Juice Shop, run challenges / traffic, then wire the tracer per portal docs.  
Destroy this stack when done (AWS ALB is hourly).

See [WALKTHROUGH.md](WALKTHROUGH.md).
