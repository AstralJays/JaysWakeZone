# JaysWakeZone ↔ SA Surf School

**Flow:** fork → clone → apply **stack 1** → install sensors/tracers.  
Later tracks = **separate** Terraform roots (containers, then Kubernetes).

## Three stacks per cloud

| # | Directory | Content | Cost posture |
|---|-----------|---------|--------------|
| 1 | `infrastructure/<cloud>/labs-1-3/` | Lab 1 Storage · Lab 2 VM and Hosts · Lab 3 Serverless | Onboarding default |
| 2 | `infrastructure/<cloud>/containers/` | ECS Fargate \| ACA | Opt-in later |
| 3 | `infrastructure/<cloud>/kubernetes/` | EKS \| AKS \| GKE | Last / destroy promptly |

Independent state → independent `apply` / `destroy`.

## Before apply — connect the account

CSPM · agentless · DSPM · activity logs / CDR.

## Stack 1 labs

| Lab | Created | You install |
|-----|---------|-------------|
| **1** Storage | Two public PII stores | — |
| **2** VM and Hosts | VM + DVWA-lite + Webmin | Host eBPF sensor |
| **3** Serverless | Lambda / App Service / Cloud Run | Tracer |

## Hygiene

One cloud. Prefer stack 1 only for onboarding day. Never leave stack 3 up overnight without a reason.
