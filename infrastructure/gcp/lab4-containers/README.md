# GCP Lab 4 — Cloud Run + Juice Shop

Separate from `lab1-3` Lab 3 (`-lab3` serverless demo).

```bash
cd infrastructure/gcp/lab4-containers
cp terraform.tfvars.example terraform.tfvars
# set project_id
terraform init && terraform apply
terraform output lab4_url
```

Image: `bkimminich/juice-shop` (Docker Hub). **No GAR.** Install tracer yourself.
