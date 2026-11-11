# SA Onboarding — Jay's Wake Zone

Facilitator guide for the two-lab SA flow. Learners pick **one** cloud (AWS | Azure | GCP) and run both labs in the same account/project.

## Goals

1. **Find exposed sensitive data** in misconfigured object storage.
2. **Exercise a purposeful vulnerable app** (DVWA-style) and map findings to runtime / vuln / attack-path views.

## Prerequisites

- Cloud CLI authenticated (`aws` / `az` / `gcloud`)
- Terraform `>= 1.5`
- Docker (optional, for local Lab 2)
- Upwind org access + sensor / CSPM connected to the lab account

## Suggested timeline (~60–90 min)

| Step | Minutes | Activity |
|------|---------|----------|
| 0 | 5 | Clone repo, pick cloud, copy `terraform.tfvars.example` |
| 1 | 10 | `terraform apply` — wait for Lab 2 first boot |
| 2 | 20 | **Lab 1** — confirm public listing, download a CSV, show CSPM / data finding |
| 3 | 30 | **Lab 2** — walk `/labs` modules; SQLi → path traversal → command injection |
| 4 | 10 | Optional sensor / runtime correlation on the Lab 2 host |
| 5 | 5 | `terraform destroy` |

## Lab 1 — Public bucket with PII

1. From Terraform outputs, open `lab1_public_url` / bucket name.
2. List objects anonymously (browser or CLI without credentials where applicable).
3. Download `exports/name-ssn-ccn.csv` or `exports/customers.json`.
4. In the console / Upwind, identify the **public storage** and **sensitive data** findings.

Expected objects:

- `exports/name-ssn-ccn.csv`
- `exports/name-ssn-dob.csv`
- `exports/name-ccn-zip.csv`
- `exports/name-dob-email.csv`
- `exports/customers.json`

## Lab 2 — Wake Zone DVWA-lite

1. Open `lab2_application_url` (port **8080**).
2. Land on `/labs` — run modules in order:
   - **SQLi login** — `' OR '1'='1`
   - **Path traversal** — read `../secret.txt` style paths
   - **Command injection** — ping helper with `; id`
   - **Hardcoded secrets** — note env / demo keys on `/labs/secrets`
3. Point Upwind (or equivalent) at the host/container and correlate.

Demo accounts (also shown in the UI):

| Email | Password |
|-------|----------|
| `jordan.lee@example.com` | `jordanwaves` |
| `admin@jayswakezone.example` | `staffadmin` |

## Teardown

```bash
cd infrastructure/<cloud>
terraform destroy
```

Confirm the public bucket/container and the VM are gone before leaving the account.
