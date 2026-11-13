# Lab 5 — Kubernetes (Agentic API Lab)

Workload: **JaysWakeZone Agentic API Lab** — one-page OWASP API + agentic threats.

App source: [`lab5-agentic/`](../lab5-agentic/)  
**You build & push** the image to Docker Hub, then point Terraform at it.

| Cloud | Path | Platform | Node |
|-------|------|----------|------|
| AWS | `infrastructure/aws/lab5-kubernetes/` | EKS | 1× `t3.small` |
| Azure | `infrastructure/azure/lab5-kubernetes/` | AKS | 1× `Standard_B2s` |
| GCP | `infrastructure/gcp/lab5-kubernetes/` | GKE | 1× `e2-small` |

```bash
# 1) publish image
cd lab5-agentic
docker build -t YOURUSER/jwz-agent-lab:0.1.0 .
docker push YOURUSER/jwz-agent-lab:0.1.0

# 2) deploy
cd ../infrastructure/aws/lab5-kubernetes   # or azure|gcp
cp terraform.tfvars.example terraform.tfvars
# container_image = "YOURUSER/jwz-agent-lab:0.1.0"
terraform init && terraform apply
terraform output lab5_url
```

**Destroy promptly.** Install the Upwind cluster sensor yourself.
