# JaysWakeZone ↔ SA Surf School

Wake Zone is the **lab pack** for [SA Surf School](https://github.com/upwindsecurity/upwind-cs-onboarding-portal) (or your portal clone).  
This repo **does not install Upwind**. The SA connects the cloud account and deploys sensors themselves.

## Before any lab — connect the account

In the SA sandbox / PoV tenant, onboard the cloud account so these light up:

| Capability | What the SA enables |
|------------|---------------------|
| **CSPM** | Misconfigurations (public storage, open SG, …) |
| **Agentless / Cloud Scanner** | Package & image inventory without a sensor |
| **DSPM** | Sensitive-data discovery on object storage |
| **CDR / activity logs** | CloudTrail · Azure Activity · GCP Audit Logs |

Portal modules: org onboarding (AWS/Azure/GCP), CloudTrail / Activity / Audit log labs.

---

## One deploy for onboarding day

**Labs 1 + 2 are a single `terraform apply`.**  
Default: `enable_lab1 = true` and `enable_lab2 = true` → two public stores **and** the host VM/app together. No separate stacks.

| Lab | What that one apply creates | SA still does | Portal ops |
|-----|----------------------------|---------------|------------|
| **1 — Storage loop** | 2 public buckets/containers + synthetic PII | Account connect only | `week-4-sa-ops-asm-map` |
| **2 — Host / eBPF** | Linux VM · DVWA-lite · Webmin | **Host sensor** install | `week-1-host-sensor`, FiU, threats |
| **3 — Kubernetes** *(later)* | EKS \| AKS \| GKE | Cluster sensor | K8s modules |
| **4 — Serverless** *(later)* | Lambda \| Cloud Run \| App Service | Tracer | Serverless modules |

Pick **one cloud**. Keep `enable_lab3` / `enable_lab4` false until those land.

---

## Lab 1 — two buckets, whole CSPM loop

| Store | Tag | SA exercise |
|-------|-----|-------------|
| `…-remediate-…` | `CspmLoop = remediate` | Alert → evidence → **fix** → reassess clear |
| `…-exception-…` | `CspmLoop = risk-accept` | Alert → **whitelist** → leave public |

Same PII in both → DSPM + CSPM on each without re-breaking.

---

## Lab 2 — host VM + attacks (same apply)

1. VM is already up from that apply (app + Webmin `admin`/`password`).
2. **SA installs the Upwind host sensor** (eBPF) — not this repo.
3. Baseline L3 / L4 / L7; run `/labs` modules + Webmin to generate detections / stories.
4. Vuln Management → **Function in use** on heartbeated CVEs.

---

## Cost / hygiene

- One cloud per SA; Labs 1–2 only for onboarding day.
- Tag for cloud-nuke / TTL; `terraform destroy` when done.
