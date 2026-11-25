# Lab 5 — EKS (Wakezone AI + Ollama GPU)

Pulls public `papaperk/jwz-agent-lab:0.1.0` — no local build.

```bash
cd Lab5/infrastructure/aws
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output lab5_url
```

CPU pool `t3.large` (Upwind headroom) + GPU `g4dn.xlarge` for Ollama. Destroy ASAP.
