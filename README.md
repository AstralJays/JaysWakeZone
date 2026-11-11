<h1 align="center">Jay's Wake Zone</h1>

<p align="center">
  SA Surf School <strong>lab pack</strong> — intentionally vulnerable sandboxes for
  <strong>AWS</strong>, <strong>Azure</strong>, or <strong>GCP</strong>.
  One clone. Pick one cloud. Connect Upwind yourself.
</p>

<p align="center">
  <a href="https://github.com/AstralJays/JaysWakeZone"><img src="https://img.shields.io/badge/org-AstralJays-24292f.svg?logo=github" alt="AstralJays" /></a>
  <img src="https://img.shields.io/badge/labs-1%20%2B%202%20%2B%204%20ready-informational.svg" alt="Labs" />
  <img src="https://img.shields.io/badge/cloud-AWS%20%7C%20Azure%20%7C%20GCP-success.svg" alt="Clouds" />
  <img src="https://img.shields.io/badge/Upwind-SA%20installs-orange.svg" alt="Upwind" />
</p>

---

> [!CAUTION]
> **Intentionally vulnerable — do not use in production.**  
> Public storage with synthetic PII, open security groups, exploitable CVEs, and Webmin (`admin` / `password`).  
> Ephemeral sandbox accounts only. `terraform destroy` when finished.

**Repository:** [AstralJays/JaysWakeZone](https://github.com/AstralJays/JaysWakeZone)  
**SA path alignment:** [docs/LEARNING-PATH.md](docs/LEARNING-PATH.md) · Facilitator: [docs/SA-ONBOARDING.md](docs/SA-ONBOARDING.md)

## How SAs use this

1. **Connect the cloud account** in Upwind (CSPM · agentless · DSPM · activity logs / CDR) — *this repo does not install Upwind*
2. Pick **one** cloud → **one** `terraform apply` (Labs **1 + 2 + 4** together by default)
3. Work storage CSPM loop, host sensor + attacks, then serverless / tracer
4. **Lab 3 (K8s)** later when ready — stays off by default

## Labs

| Lab | Same apply creates | You install | Learning outcome |
|-----|--------------------|-------------|------------------|
| **1 — Storage loop** | **Two** public buckets/containers + synthetic PII | — (account connect) | CSPM + DSPM; **remediate** one, **risk-accept** the other |
| **2 — Host / eBPF** | Linux VM · DVWA-lite · Webmin `:10000` | Host sensor | L3/L4/L7 baseline + detections; FiU; exposed mgmt |
| **4 — Serverless** | Lambda **or** App Service **or** Cloud Run | Tracer | Agentless / image CVEs + serverless runtime |
| **3 — Kubernetes** | EKS \| AKS \| GKE | Cluster sensor | *Planned* — `lab3-kubernetes/` |

## Quick start — one apply

```bash
git clone https://github.com/AstralJays/JaysWakeZone.git
cd JaysWakeZone

# Example: AWS  →  buckets + VM/app + Lambda in one go
cd infrastructure/aws
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output
```

Azure / GCP: same under `infrastructure/azure` or `infrastructure/gcp`.

```hcl
enable_lab1 = true    # two PII stores
enable_lab2 = true    # host VM + app + Webmin
enable_lab4 = true    # serverless (Lambda / App Service / Cloud Run)
enable_lab3 = false   # K8s later
```

### After apply

**Lab 1** — `lab1_remediate_*` (fix) · `lab1_exception_*` (risk-accept)  
**Lab 2** — `lab2_application_url` · `lab2_webmin_url` (`admin` / `password`) · install host sensor on `lab2_public_ip`  
**Lab 4** — `lab4_function_url` (AWS) · `lab4_app_url` (Azure) · `lab4_service_url` (GCP)

### Lab 4 (no ECR / ACR / GAR / Actions)

| Cloud | How it deploys |
|-------|----------------|
| AWS | **Zip Lambda** + Function URL |
| Azure / GCP | Pull public Docker Hub `python:3.9-bullseye`, boot installs Flask 2.0.3 |

## Layout

```
lab1-public-data/       Synthetic PII seeds
lab2-wakezone-app/      Host DVWA-lite + FiU
lab3-kubernetes/        Planned — EKS | AKS | GKE
lab4-serverless/        Flask image + Lambda zip handler
infrastructure/aws|azure|gcp
docs/LEARNING-PATH.md
docs/SA-ONBOARDING.md
scripts/                VM install (app + Webmin) — no Upwind
```

## Safety

- Not for production. All vulns and exposures are intentional.
- One cloud per SA; destroy when the session ends.
- Synthetic PII only (dlptest-style patterns).
