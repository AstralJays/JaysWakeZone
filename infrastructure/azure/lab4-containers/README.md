# Azure Lab 4 — Container Apps + Juice Shop

```bash
cd infrastructure/azure/lab4-containers
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output lab4_url
```

Image: `bkimminich/juice-shop` (Docker Hub). **No ACR.** Install tracer yourself.
