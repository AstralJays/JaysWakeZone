# Azure stack 2/3 — Container Apps (Lab 4)

```bash
cd infrastructure/azure/containers
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output lab4_url
```

Public Docker Hub image, min replicas 0. Destroy when finished. Install tracer yourself.
