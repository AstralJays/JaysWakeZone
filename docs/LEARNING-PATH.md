# JaysWakeZone ↔ SA Surf School

Wake Zone is the **lab pack** for [SA Surf School](https://github.com/upwindsecurity/upwind-cs-onboarding-portal) (or your portal clone).  
This repo **does not install Upwind**. The SA connects the cloud account and deploys sensors / tracers themselves.

## Before any lab — connect the account

| Capability | What the SA enables |
|------------|---------------------|
| **CSPM** | Misconfigurations (public storage, open SG, …) |
| **Agentless / Cloud Scanner** | Package & image inventory without a sensor |
| **DSPM** | Sensitive-data discovery on object storage |
| **CDR / activity logs** | CloudTrail · Azure Activity · GCP Audit Logs |

---

## One deploy for onboarding day

**Labs 1 + 2 + 4 are a single `terraform apply`.**  
Default: storage + host VM + serverless. **Lab 3 (K8s) stays off** until you are ready for that track.

| Lab | What that one apply creates | SA still does | Portal ops |
|-----|----------------------------|---------------|------------|
| **1 — Storage loop** | 2 public buckets/containers + synthetic PII | Account connect only | `week-4-sa-ops-asm-map` |
| **2 — Host / eBPF** | Linux VM · DVWA-lite · Webmin | **Host sensor** | `week-1-host-sensor`, FiU, threats |
| **4 — Serverless** | Lambda \| App Service \| Cloud Run | **Tracer** | Serverless / agentless image modules |
| **3 — Kubernetes** *(later)* | EKS \| AKS \| GKE | Cluster sensor | K8s modules |

Pick **one cloud**.

---

## Lab 1 — two buckets, whole CSPM loop

| Store | Tag | SA exercise |
|-------|-----|-------------|
| `…-remediate-…` | `CspmLoop = remediate` | Alert → evidence → **fix** → reassess clear |
| `…-exception-…` | `CspmLoop = risk-accept` | Alert → **whitelist** → leave public |

---

## Lab 2 — host VM + attacks (same apply)

1. VM is already up (app + Webmin `admin`/`password`).
2. **SA installs the Upwind host sensor** (eBPF).
3. Baseline L3 / L4 / L7; run `/labs` + Webmin → detections / stories / FiU.

---

## Lab 4 — serverless (same apply)

| Cloud | Deploy shape | Registry? |
|-------|--------------|-----------|
| AWS | Lambda zip + Function URL | **None** |
| Azure | App Service ← Docker Hub `python:3.9-bullseye` | **None** (public Hub) |
| GCP | Cloud Run ← Docker Hub `python:3.9-bullseye` | **None** (public Hub) |

No Actions / no image push. Boot command pip-installs Flask 2.0.3 on the old bullseye base (agentless CVE candidate). SA installs the tracer themselves.

---

## Cost / hygiene

- One cloud per SA; Labs 1 + 2 + 4 for onboarding day.
- Lab 3 off until K8s week (`enable_lab3 = false`).
- `terraform destroy` when done.
