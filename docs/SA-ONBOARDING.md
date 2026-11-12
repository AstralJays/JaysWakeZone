# SA Onboarding — facilitator runbook

**Grab and go:** fork → clone → one `terraform apply` (Labs 1–3) → SA installs sensors.  
Labs 4–5 stay off for cost unless the SA is on that track.

## SA checklist (onboarding day)

1. Fork [AstralJays/JaysWakeZone](https://github.com/AstralJays/JaysWakeZone)
2. Clone **their** fork
3. Connect sandbox cloud in Upwind (CSPM · agentless · DSPM · activity logs)
4. `cd infrastructure/<aws|azure|gcp>` → copy tfvars → `terraform init && apply`
5. Lab 1 CSPM loop → Lab 2 VM and Hosts → Lab 3 tracer
6. `terraform destroy`

## tfvars

| Cloud | Required |
|-------|----------|
| AWS | Usually nothing (region/profile optional) |
| Azure | `ssh_public_key` |
| GCP | `project_id` |

```hcl
enable_lab1 = true
enable_lab2 = true
enable_lab3 = true
enable_lab4 = false  # ECS / ACA — later
enable_lab5 = false  # EKS / AKS / GKE — last
```

## Timeline (~half day)

| Step | Min | Activity |
|------|-----|----------|
| 0 | 15 | Connect cloud account in Upwind |
| 1 | 15 | One `terraform apply` (1–3 only) |
| 2 | 25 | Lab 1 — remediate one store, risk-accept the other |
| 3 | 15 | Install host eBPF sensor (Lab 2 VM and Hosts) |
| 4 | 30 | Lab 2 attacks — `/labs` + Webmin |
| 5 | 20 | Lab 3 — hit URL, install tracer |
| 6 | 5 | `terraform destroy` |

## Later tracks (cost)

| Lab | When | Flag |
|-----|------|------|
| **4** Managed containers | After day-1; ECS Fargate / ACA | `enable_lab4` |
| **5** Kubernetes | Last; EKS / AKS / GKE | `enable_lab5` |

Prefer destroying day-1 resources before standing up Lab 4 or 5.
