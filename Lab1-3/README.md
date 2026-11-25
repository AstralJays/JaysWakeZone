# Lab 1–3 — Storage · VM · Serverless

One Terraform apply per cloud deploys Labs **1**, **2**, and **3**.

| Lab | Assets | What |
|-----|--------|------|
| 1 Storage | `lab1-public-data/` | Public buckets + synthetic PII |
| 2 VM/Hosts | `lab2-hosts-vms/` | DVWA-lite host (scripts install from clone) |
| 3 Serverless | `lab3-serverless/` | Lambda / App Service / Cloud Run |

## Deploy

```bash
cd Lab1-3/infrastructure/<aws|azure|gcp>
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

See [docs/HOST-ACCESS.md](../docs/HOST-ACCESS.md) for Lab 2 SSM / SSH (Upwind host sensor).
