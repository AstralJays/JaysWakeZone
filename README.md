<h1 align="center">Jay's Wake Zone</h1>

<p align="center">
  <strong>Grab-and-go</strong> SA Surf School labs — fork, clone, <code>terraform apply</code>.
  No image builds. You install Upwind sensors yourself.
</p>

<p align="center">
  <a href="https://github.com/AstralJays/JaysWakeZone"><img src="https://img.shields.io/badge/org-AstralJays-24292f.svg?logo=github" alt="AstralJays" /></a>
  <img src="https://img.shields.io/badge/cloud-AWS%20%7C%20Azure%20%7C%20GCP-success.svg" alt="Clouds" />
  <img src="https://img.shields.io/badge/stacks-3%20per%20cloud-informational.svg" alt="Stacks" />
</p>

---

> [!CAUTION]
> **Intentionally vulnerable — do not use in production.**  
> Sandbox accounts only. Destroy each stack when finished — especially Kubernetes.

## Three independent stacks (per cloud)

| Stack | Path | Apps / platforms | Cost |
|-------|------|------------------|------|
| **1 — Labs 1–3** | `…/labs-1-3/` | Storage · VM and Hosts · Serverless | Day-1 default |
| **2 — Containers** | `…/containers/` | ECS Fargate \| ACA \| Cloud Run | Opt-in (ALB on AWS) |
| **3 — Kubernetes** | `…/kubernetes/` | EKS \| AKS \| GKE + Flask workload | Last — destroy ASAP |

```text
infrastructure/<aws|azure|gcp>/
  labs-1-3/     ← onboarding day
  containers/   ← Lab 4 apps live
  kubernetes/   ← Lab 5 apps live
```

## Grab and go (stack 1)

```bash
git clone https://github.com/<YOU>/JaysWakeZone.git
cd JaysWakeZone/infrastructure/aws/labs-1-3   # or azure|gcp
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply && terraform output
```

Azure: set `ssh_public_key`. GCP: set `project_id`.

## What’s deployed

| Lab | App | Stack |
|-----|-----|-------|
| **1** Storage | Two public PII stores (`lab1-public-data/`) | 1 |
| **2** VM and Hosts | DVWA-lite + Webmin (`lab2-wakezone-app/`) | 1 |
| **3** Serverless | Lambda zip / App Service / Cloud Run (`lab3-serverless/`) | 1 |
| **4** Containers | Flask on `python:3.9-bullseye` (`lab4-containers/`) | 2 |
| **5** Kubernetes | Same Flask via Deployment+LB (`lab5-kubernetes/`) | 3 |

All container workloads pull **public Docker Hub** — no ECR/ACR/GAR push.

### Stack 2 / 3

```bash
cd infrastructure/<cloud>/containers   # or kubernetes
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output   # lab4_url or lab5_url
```

## Cost hygiene

- Onboarding = **stack 1 only**.
- Stack 2 AWS includes an ALB (hourly) — destroy when done.
- Stack 3 pays for control plane + node — never leave overnight without intent.
- Each stack has its own state → destroy independently.

## Before labs

Connect the sandbox cloud in Upwind (CSPM · agentless · DSPM · activity logs / CDR).

[docs/LEARNING-PATH.md](docs/LEARNING-PATH.md) · [docs/SA-ONBOARDING.md](docs/SA-ONBOARDING.md)
