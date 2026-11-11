# SA Onboarding — facilitator runbook

Aligned with **SA Surf School**: account connect → Labs 1 + 2 + 4 (one apply) → console ops.  
Wake Zone **never** installs Upwind — the SA does CSPM / agentless / DSPM / CDR + sensors / tracers.

## Prerequisites

- Sandbox cloud account (AWS *or* Azure *or* GCP)
- Terraform `>= 1.5`, cloud CLI
- Upwind org access
- For Azure/GCP Lab 4: Docker Hub `python:3.9-bullseye` (no custom image publish)

## Timeline (~half day)

Labs **1 + 2 + 4 are one deployment**. Lab 3 (K8s) is a later day.

| Step | Min | Activity |
|------|-----|----------|
| 0 | 15 | SA connects cloud account (CSPM, agentless, DSPM, activity logs) |
| 1 | 15 | **One** `terraform apply` → stores + VM/app + serverless |
| 2 | 25 | **Lab 1 CSPM loop** — remediate store A, risk-accept store B |
| 3 | 15 | SA installs **host eBPF sensor** on Lab 2 |
| 4 | 30 | **Lab 2 attacks** — DVWA + Webmin; L3/L4/L7 + FiU + Stories |
| 5 | 20 | **Lab 4** — hit function/service URL; install tracer; agentless on image (Azure/GCP) |
| 6 | 5 | `terraform destroy` |

## Lab 1 — two-store CSPM / DSPM loop

Outputs: `lab1_remediate_*` and `lab1_exception_*`.

## Lab 2 — host sensor + DVWA

Outputs: `lab2_application_url`, `lab2_webmin_url` (`admin` / `password`), `lab2_public_ip`.

## Lab 4 — serverless / tracer

| Cloud | Output |
|-------|--------|
| AWS | `lab4_function_url` (zip Lambda — no ECR) |
| Azure | `lab4_app_url` (App Service ← Docker Hub) |
| GCP | `lab4_service_url` (Cloud Run ← Docker Hub) |

## Lab 3 (later)

Keep `enable_lab3 = false` until EKS/AKS/GKE content lands in `lab3-kubernetes/`.

## Teardown

```bash
cd infrastructure/<cloud>
terraform destroy
```
