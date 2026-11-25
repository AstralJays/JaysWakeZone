# Lab 4 — Abstracted container services

OWASP Juice Shop on managed containers. **No image build** — pulls public `bkimminich/juice-shop`.

| Cloud | Path | Platform |
|-------|------|----------|
| AWS | `infrastructure/aws/` | ECS Fargate + ALB |
| Azure | `infrastructure/azure/` | Azure Container Apps |
| GCP | `infrastructure/gcp/` | Cloud Run |

## Configure

```bash
cd Lab4/infrastructure/<aws|azure|gcp>
cp terraform.tfvars.example terraform.tfvars
```

| Cloud | Edit in `terraform.tfvars` |
|-------|----------------------------|
| **AWS** | `aws_region` (default `us-east-1`). Optional: `aws_profile`. |
| **Azure** | `location` (default `eastus`). |
| **GCP** | **Required:** `project_id`. Optional: `region`. |

`container_image` is optional — default is Juice Shop on Docker Hub.

## Deploy

```bash
terraform init
terraform apply
terraform output lab4_url
```

Open the URL → Juice Shop UI. First cold start can take a minute (image pull).

## Destroy

```bash
terraform destroy
```

Destroy when finished — **AWS ALB costs money while the stack is up**.

## After apply (Upwind)

Install the **tracer** for this service yourself (portal / console). Then browse the shop and run a few challenges so runtime / image findings show up.

See [WALKTHROUGH.md](WALKTHROUGH.md).
