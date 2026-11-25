# Lab 5 — AKS (Wakezone AI + Ollama GPU)

Publish `Lab5/` to Docker Hub, set `container_image`, then:

```bash
cd Lab5/infrastructure/azure
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output lab5_url
```

CPU pool `Standard_D2s_v5` + GPU `Standard_NC4as_T4_v3`. Destroy ASAP.
