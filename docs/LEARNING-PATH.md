# JaysWakeZone ↔ SA Surf School

**Flow:** fork → clone locally → `terraform apply` → install sensors/tracers in Upwind.  
No container image builds or registry work for the SA.

## Before apply — connect the account

| Capability | SA enables in Upwind |
|------------|----------------------|
| **CSPM** | Misconfigurations |
| **Agentless** | Package / image inventory |
| **DSPM** | Sensitive data on object storage |
| **CDR / activity logs** | CloudTrail · Activity · Audit Logs |

## One apply

Defaults: Labs **1 + 2 + 3**. Lab **4 (K8s)** last (`enable_lab4 = false`).

| Lab | Created for you | You install |
|-----|-----------------|-------------|
| **1** Storage | Two public PII stores | — (use console CSPM/DSPM loop) |
| **2** VM and Hosts | Linux VM + DVWA-lite + Webmin | Host eBPF sensor |
| **3** Serverless | Lambda / App Service / Cloud Run | Tracer |
| **4** Kubernetes | — (later) | Cluster sensor |

## Lab notes

**Lab 1** — `remediate` store = fix public access; `exception` store = whitelist / accept risk.  
**Lab 2 — VM and Hosts** — baseline L3/L4/L7, then attack `/labs` + Webmin (`admin`/`password`).  
**Lab 3** — Terraform handles packaging/public images; SA only hits the URL and installs the tracer.  
**Lab 4** — EKS / AKS / GKE when ready; stays off for onboarding day.

## Hygiene

One cloud per SA. `terraform destroy` when done.
