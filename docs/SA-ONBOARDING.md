# SA Onboarding — facilitator runbook

**Grab and go:** fork → clone → one `terraform apply` → SA installs sensors.  
No image builds. No Upwind install in this repo.

## SA checklist

1. Fork [AstralJays/JaysWakeZone](https://github.com/AstralJays/JaysWakeZone)
2. Clone **their** fork
3. Connect sandbox cloud in Upwind (CSPM · agentless · DSPM · activity logs)
4. `cd infrastructure/<aws|azure|gcp>` → copy tfvars → `terraform init && apply`
5. Lab 1 CSPM loop → Lab 2 host sensor + attacks → Lab 4 tracer
6. `terraform destroy`

## tfvars they must set

| Cloud | Required |
|-------|----------|
| AWS | Usually nothing (region/profile optional) |
| Azure | `ssh_public_key` |
| GCP | `project_id` |

Leave `enable_lab1/2/4 = true`, `enable_lab3 = false`.  
Leave `repo_url` alone unless they edited Lab 2 code in the fork.

## Timeline (~half day)

| Step | Min | Activity |
|------|-----|----------|
| 0 | 15 | Connect cloud account in Upwind |
| 1 | 15 | One `terraform apply` |
| 2 | 25 | Lab 1 — remediate one store, risk-accept the other |
| 3 | 15 | Install host eBPF sensor on Lab 2 |
| 4 | 30 | Lab 2 attacks — `/labs` + Webmin |
| 5 | 20 | Lab 4 — hit URL, install tracer |
| 6 | 5 | `terraform destroy` |

## Outputs

- Lab 1: `lab1_remediate_*` / `lab1_exception_*`
- Lab 2: `lab2_application_url`, `lab2_webmin_url` (`admin` / `password`), `lab2_public_ip`
- Lab 4: `lab4_function_url` \| `lab4_app_url` \| `lab4_service_url`

## Lab 3 later

Keep K8s off until `lab3-kubernetes/` is ready.
