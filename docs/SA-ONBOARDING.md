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

## Lab 2 — Wake Zone DVWA-lite (+ Function in use)

1. Open `lab2_application_url` (port **8080**).
2. **Function in use first** — six CVEs, all heartbeating every 60s:

   | Lab | CVE | Function | Exploit |
   |-----|-----|----------|---------|
   | `/labs/fiu-pillow-imagemath` | CVE-2023-50447 | `PIL.ImageMath.eval` | `POST /api/board/preview` |
   | `/labs/fiu-pillow-jpeg` | CVE-2026-112403 | `Image.thumbnail` → JPEG decode | `POST /api/image/thumbnail` |
   | `/labs/fiu-pillow-eps` | CVE-2026-112900 | `EpsImagePlugin` → Ghostscript | `POST /api/image/eps` |
   | `/labs/fiu-brotli` | CVE-2026-111497 | `DecodeBlockTypeAndLength` | `POST /api/decode/brotli` |
   | `/labs/fiu-yaml` | CVE-2020-14343 | `yaml.load(Loader=…)` | `POST /api/checkout` |
   | `/labs/fiu-tarfile` | CVE-2007-4559 | `TarFile.extractall` | `POST /api/archive/extract` |

   - In Upwind: Vulnerabilities → filter **Function in use**
   - Skipped on purpose: XXE CVE-2022-48565 (needs ancient CPython), SymPy/Triton (too heavy), interpreter CVEs (2021-29921 / 3177 / 2022-37454)
3. Classic modules:
   - **SQLi login** — `' OR '1'='1`
   - **Path traversal** — `../secret.txt`
   - **Command injection** — `; id`
   - **Hardcoded secrets** — `/labs/secrets`
4. **Exposed Webmin** — `lab2_webmin_url` (`https://IP:10000`)
   - Credentials: **`admin` / `password`**
   - Story: internet-facing Linux admin UI → weak creds → full host compromise (sudo)
5. Sensor tip: `inuse-python=true,inuse-skip-young-process=false` (defaults in `terraform.tfvars.example`).

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
