# Lab 4 — Managed containers (app)

Demo workload: public `python:3.9-bullseye` + Flask 2.0.3 (agentless CVE candidate).  
**No image build/push** — Terraform bootstraps at start.

| Cloud | Stack path | Platform |
|-------|------------|----------|
| AWS | `infrastructure/aws/lab4-containers/` | ECS Fargate + ALB |
| Azure | `infrastructure/azure/lab4-containers/` | Azure Container Apps |
| GCP | `infrastructure/gcp/lab4-containers/` | Cloud Run (containers track) |

SA installs the tracer after apply. Destroy this stack when done.
