# AWS stack 3/3 — EKS (Lab 5) — Agentic API Lab

Publish `lab5-agentic/` to Docker Hub, set `container_image`, then:

```bash
cd infrastructure/aws/lab5-kubernetes
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output
```

**Destroy promptly.** Install the Upwind cluster/node sensor yourself.
