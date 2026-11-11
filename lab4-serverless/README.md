# Lab 4 — Serverless / container (same apply as Labs 1–2)

Ships with the default onboarding deploy (`enable_lab4 = true`). Kubernetes stays Lab 3 later.

| Cloud | What Terraform creates | Image / package |
|-------|------------------------|-----------------|
| **AWS** | Lambda + Function URL | **Zip** of `lambda/handler.py` — no ECR |
| **Azure** | App Service (Linux container) | Public **GHCR** image |
| **GCP** | Cloud Run | Public **GHCR** image |

## Why not ECR / ACR / GAR?

Cloud Run and App Service can pull a **public** image. We build once via GitHub Actions to:

`ghcr.io/astraljays/jayswakezone-flask:3.9-bullseye`

Lambda container images *require* ECR, so AWS uses a zip function instead (same demo JSON, no registry).

## Local image (optional)

```bash
cd lab4-serverless
docker build -t jayswakezone-flask:3.9-bullseye .
docker run --rm -p 8080:8080 jayswakezone-flask:3.9-bullseye
```

Override in tfvars if needed:

```hcl
serverless_image = "ghcr.io/astraljays/jayswakezone-flask:3.9-bullseye"
```

## SA exercise

1. Confirm the function / service URL responds.
2. Install tracer / serverless instrumentation yourself (not in this repo).
3. Agentless / image scan: expect findings on the bullseye + old Flask/Werkzeug pins (Azure/GCP).
