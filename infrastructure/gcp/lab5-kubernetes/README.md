# GCP stack 3/3 — GKE (Lab 5) — Agentic API Lab

Publish `lab5-agentic/` to Docker Hub, set `container_image` + `project_id`, then:

```bash
cd infrastructure/gcp/lab5-kubernetes
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output
```

**Destroy promptly.** Install the Upwind cluster/node sensor yourself.
