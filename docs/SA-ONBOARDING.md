# SA Onboarding — facilitator runbook

**Grab and go:** fork → clone → one `terraform apply` → SA installs sensors.  
No image builds. No Upwind install in this repo.

## SA checklist

1. Fork [AstralJays/JaysWakeZone](https://github.com/AstralJays/JaysWakeZone)
2. Clone **their** fork
3. Connect sandbox cloud in Upwind (CSPM · agentless · DSPM · activity logs)
4. `cd infrastructure/<aws|azure|gcp>` → copy tfvars → `terraform init && apply`
5. Lab 1 CSPM loop → Lab 2 VM and Hosts → Lab 3 tracer
6. `terraform destroy`

## tfvars they must set

| Cloud | Required |
|-------|----------|
| AWS | Usually nothing (region/profile optional) |
| Azure | `ssh_public_key` |
| GCP | `project_id` |

Leave `enable_lab1/2/3 = true`, `enable_lab4 = false`.  
Leave `repo_url` alone unless they edited Lab 2 code in the fork.

## Timeline (~half day)

| Step | Min | Activity |
|------|-----|----------|
| 0 | 15 | Connect cloud account in Upwind |
| 1 | 15 | One `terraform apply` |
| 2 | 25 | Lab 1 — remediate one store, risk-accept the other |
| 3 | 15 | Install host eBPF sensor on Lab 2 (VM and Hosts) |
| 4 | 30 | Lab 2 attacks — `/labs` + Webmin |
| 5 | 20 | Lab 3 — hit URL, install tracer |
| 6 | 5 | `terraform destroy` |

## Outputs

- Lab 1: `lab1_remediate_*` / `lab1_exception_*`
- Lab 2: `lab2_application_url`, `lab2_webmin_url` (`admin` / `password`), `lab2_public_ip`
- Lab 3: `lab3_function_url` \| `lab3_app_url` \| `lab3_service_url`

## Lab 4 later (Kubernetes)

Keep `enable_lab4 = false` until `lab4-kubernetes/` is ready.
