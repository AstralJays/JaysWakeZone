# JaysWakeZone ↔ SA Surf School

**Flow:** fork → clone → `terraform apply` → install sensors/tracers in Upwind.  
No container image builds or registry work for the SA.

## Before apply — connect the account

| Capability | SA enables in Upwind |
|------------|----------------------|
| **CSPM** | Misconfigurations |
| **Agentless** | Package / image inventory |
| **DSPM** | Sensitive data on object storage |
| **CDR / activity logs** | CloudTrail · Activity · Audit Logs |

## Lab map (cost-minded)

**Onboarding day:** Labs **1 + 2 + 3** only.  
**Later tracks:** Lab **4** managed containers, Lab **5** Kubernetes — both **off** by default.

| Lab | Created for you | You install | Default |
|-----|-----------------|-------------|---------|
| **1** Storage | Two public PII stores | — | on |
| **2** VM and Hosts | Linux VM + DVWA-lite + Webmin | Host eBPF sensor | on |
| **3** Serverless | Lambda / App Service / Cloud Run | Tracer | on |
| **4** Managed containers | ECS Fargate \| Azure Container Apps | Tracer | **off** |
| **5** Kubernetes | EKS \| AKS \| GKE | Cluster sensor | **off** |

## Lab notes

**Lab 1** — `remediate` store = fix; `exception` store = whitelist / accept risk.  
**Lab 2 — VM and Hosts** — baseline L3/L4/L7, then `/labs` + Webmin (`admin`/`password`).  
**Lab 3** — hit URL; install tracer. No image push.  
**Lab 4** — container platforms without full K8s tax; enable only when needed.  
**Lab 5** — last / most expensive; destroy promptly.

## Hygiene

One cloud per SA. `terraform destroy` when done. Never leave Lab 5 up overnight without a reason.
