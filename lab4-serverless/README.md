# Lab 4 — Serverless (same apply as Labs 1–2)

| Cloud | What Terraform creates | Image / package |
|-------|------------------------|-----------------|
| **AWS** | Lambda + Function URL | **Zip** of `lambda/handler.py` — no registry |
| **Azure** | App Service (Linux container) | Public Docker Hub `python:3.9-bullseye` + boot command |
| **GCP** | Cloud Run | Public Docker Hub `python:3.9-bullseye` + boot command |

No GitHub Actions, no ECR / ACR / GAR, no image push.  
Azure/GCP pull **`python:3.9-bullseye`** and run `boot.sh` logic (pip install old Flask, start app). Agentless still sees the old Debian base.

`Dockerfile` + `app.py` are optional local builds only.

## Override image

```hcl
serverless_image = "python:3.9-bullseye"
```
