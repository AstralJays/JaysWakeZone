# Lab 5 — GKE (Wakezone AI + Ollama GPU)

Pulls public `papaperk/jwz-agent-lab:0.1.0` — no local build. Set `project_id`.

```bash
cd Lab5/infrastructure/gcp
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output lab5_url
```

CPU `e2-standard-2` + T4 GPU pool. Destroy ASAP.
