# Lab 4 — Abstracted container services

OWASP Juice Shop on managed containers (public image — no build).

| Cloud | Path | Platform |
|-------|------|----------|
| AWS | `infrastructure/aws/` | ECS Fargate + ALB |
| Azure | `infrastructure/azure/` | Azure Container Apps |
| GCP | `infrastructure/gcp/` | Cloud Run |

```bash
cd Lab4/infrastructure/aws   # or azure|gcp
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output lab4_url
```

See [WALKTHROUGH.md](WALKTHROUGH.md). Destroy when finished.
