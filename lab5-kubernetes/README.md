# Lab 5 — Kubernetes (app + manifests)

Workload: same Flask CVE demo on public `python:3.9-bullseye`.

| Cloud | Stack path | Platform |
|-------|------------|----------|
| AWS | `infrastructure/aws/lab5-kubernetes/` | EKS (1× managed node) |
| Azure | `infrastructure/azure/lab5-kubernetes/` | AKS (1× small node) |
| GCP | `infrastructure/gcp/lab5-kubernetes/` | GKE (1× small node) |

Reference manifests: `manifests/deployment.yaml`.  
**Destroy promptly** — control plane + node hours add up. SA installs cluster sensor themselves.
