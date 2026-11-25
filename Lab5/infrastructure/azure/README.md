# Lab 5 — AKS (Wakezone AI + Ollama GPU)

Pulls public `papaperk/jwz-agent-lab:0.1.0` — no local build.

```bash
cd Lab5/infrastructure/azure
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output lab5_url
```

CPU pool `Standard_D2s_v5` + GPU `Standard_NC4as_T4_v3`. Destroy ASAP.
