# GCP stack 3/3 — GKE (Lab 5) — Damn Vulnerable AI Agent

```bash
cd infrastructure/gcp/lab5-kubernetes
cp terraform.tfvars.example terraform.tfvars   # set project_id
terraform init && terraform apply
terraform output
```

Pulls [`opena2a/dvaa:0.9.2`](https://hub.docker.com/r/opena2a/dvaa) onto 1× `e2-medium` behind a LoadBalancer (dashboard).  
**Destroy promptly.** Install the Upwind cluster/node sensor yourself.
