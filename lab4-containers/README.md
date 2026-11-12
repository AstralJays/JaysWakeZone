# Lab 4 — Managed containers (planned)

**Status:** stub — `enable_lab4 = false` by default (cost).  
Comes **after** Labs 1–3 onboarding day; **before** Kubernetes.

| Cloud | Target | Notes |
|-------|--------|--------|
| AWS | **ECS Fargate** | Tracer path; no cluster nodes to babysit |
| Azure | **Azure Container Apps** | Same idea as Fargate/ACA |
| GCP | Optional / thin | Cloud Run already covers a lot in Lab 3 |

**SA owns:** tracer / container instrumentation (not in Terraform).  
**Wake Zone will provide:** public-image workload (no ECR/ACR/GAR push for the SA), scale-to-zero where the platform allows.

Keep this off unless you are on the containers track. Prefer destroying Labs 1–3 first if you are cost-sensitive.
