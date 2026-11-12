# Azure stack 3/3 — AKS (Lab 5) — Damn Vulnerable AI Agent

```bash
cd infrastructure/azure/lab5-kubernetes
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output
```

Pulls [`opena2a/dvaa:0.9.2`](https://hub.docker.com/r/opena2a/dvaa) onto 1× `Standard_B2s` behind a LoadBalancer (dashboard).  
**Destroy promptly.** Install the Upwind cluster/node sensor yourself.
