# Lab 5 — GKE (Wakezone AI + Ollama GPU)

Publish `Lab5/` to Docker Hub, set `container_image` + `project_id`, then:

```bash
cd Lab5/infrastructure/gcp
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output lab5_url
```

CPU `e2-standard-2` + T4 GPU pool. Destroy ASAP.
