# SA Onboarding — facilitator runbook

**Grab and go:** fork → clone → apply **stack 1** (`labs-1-3`) → SA installs sensors.  
Stacks 2–3 are separate deploys — leave them until that track.

## SA checklist (onboarding day)

1. Fork [AstralJays/JaysWakeZone](https://github.com/AstralJays/JaysWakeZone)
2. Clone **their** fork
3. Connect sandbox cloud in Upwind
4. `cd infrastructure/<aws|azure|gcp>/labs-1-3`
5. Copy tfvars → `terraform init && apply && output`
6. Lab 1 → Lab 2 VM and Hosts → Lab 3 tracer
7. `terraform destroy` **in labs-1-3 only**

## tfvars

| Cloud | Required in `labs-1-3` |
|-------|------------------------|
| AWS | Usually nothing |
| Azure | `ssh_public_key` |
| GCP | `project_id` |

## Later tracks (separate applies)

```bash
# Stack 2 — when ready
cd infrastructure/<cloud>/containers
terraform init && terraform apply

# Stack 3 — last / expensive
cd infrastructure/<cloud>/kubernetes
terraform init && terraform apply
```

Destroy each stack from its own directory.

## Outputs (stack 1)

- Lab 1: `lab1_remediate_*` / `lab1_exception_*`
- Lab 2: `lab2_application_url`, `lab2_webmin_url` (`admin` / `password`), `lab2_public_ip`
- Lab 3: `lab3_function_url` \| `lab3_app_url` \| `lab3_service_url`
