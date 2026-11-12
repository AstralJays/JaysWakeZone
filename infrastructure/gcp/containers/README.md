# GCP stack 2/3 — Cloud Run containers track (Lab 4)

Separate from `labs-1-3` Lab 3 serverless service (`-lab3` vs `-lab4`).

```bash
cd infrastructure/gcp/containers
cp terraform.tfvars.example terraform.tfvars
# set project_id
terraform init && terraform apply
terraform output lab4_url
```
