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

Defaults: Labs **1 + 2 + 4**. Lab **3 (K8s)** later (`enable_lab3 = false`).

| Lab | Created for you | You install |
|-----|-----------------|-------------|
| **1** | Two public PII stores | — (use console CSPM/DSPM loop) |
| **2** | VM + DVWA-lite + Webmin | Host eBPF sensor |
| **4** | Lambda / App Service / Cloud Run | Tracer |
| **3** | — | Cluster sensor (later) |

## Lab notes

**Lab 1** — `remediate` store = fix public access; `exception` store = whitelist / accept risk.  
**Lab 2** — baseline L3/L4/L7, then attack `/labs` + Webmin (`admin`/`password`).  
**Lab 4** — Terraform handles packaging/public images; SA only hits the URL and installs the tracer.

## Hygiene

One cloud per SA. `terraform destroy` when done.
