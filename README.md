<h1 align="center">Jay's Wake Zone</h1>

<p align="center">
  SA Surf School <strong>lab pack</strong> — intentionally vulnerable sandboxes for
  <strong>AWS</strong>, <strong>Azure</strong>, or <strong>GCP</strong>.
  One clone. Pick one cloud. Connect Upwind yourself.
</p>

<p align="center">
  <a href="https://github.com/AstralJays/JaysWakeZone"><img src="https://img.shields.io/badge/org-AstralJays-24292f.svg?logo=github" alt="AstralJays" /></a>
  <img src="https://img.shields.io/badge/labs-1%20%2B%202%20ready-informational.svg" alt="Labs" />
  <img src="https://img.shields.io/badge/cloud-AWS%20%7C%20Azure%20%7C%20GCP-success.svg" alt="Clouds" />
  <img src="https://img.shields.io/badge/Upwind-SA%20installs-orange.svg" alt="Upwind" />
</p>

---

> [!CAUTION]
> **Intentionally vulnerable — do not use in production.**  
> Public storage with synthetic PII, open security groups, exploitable CVEs, and Webmin (`admin` / `password`).  
> Ephemeral sandbox accounts only. `terraform destroy` when finished.

**Repository:** [AstralJays/JaysWakeZone](https://github.com/AstralJays/JaysWakeZone)  
**SA path alignment:** [docs/LEARNING-PATH.md](docs/LEARNING-PATH.md) · Facilitator: [docs/SA-ONBOARDING.md](docs/SA-ONBOARDING.md)

## How SAs use this

1. **Connect the cloud account** in Upwind (CSPM · agentless · DSPM · activity logs / CDR) — *this repo does not install Upwind*
2. Pick **one** cloud → **one** `terraform apply` (Labs **1 + 2** together by default)
3. Work Lab 1 (CSPM/DSPM loop), then install the **host eBPF sensor** and run Lab 2 attacks
4. Operate findings in the console per SA Surf School Week 4 ops

## Labs

| Lab | Same apply creates | You install | Learning outcome |
|-----|--------------------|-------------|------------------|
| **1 — Storage loop** | **Two** public buckets/containers + synthetic PII | — (account connect) | CSPM + DSPM; **remediate** one, **risk-accept** the other |
| **2 — Host / eBPF** | Linux VM · DVWA-lite · Webmin `:10000` | Host sensor | L3/L4/L7 baseline + detections; FiU; exposed mgmt |
| **3 — Kubernetes** | EKS \| AKS \| GKE | Cluster sensor | *Planned* — `lab3-kubernetes/` |
| **4 — Serverless tracer** | Lambda \| Cloud Run \| App Service | Tracer | *Planned* — `lab4-serverless/` |

## Quick start — one apply

```bash
git clone https://github.com/AstralJays/JaysWakeZone.git
cd JaysWakeZone

# Example: AWS  →  buckets + VM/app in one go
cd infrastructure/aws
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output
```

Azure / GCP: same under `infrastructure/azure` or `infrastructure/gcp`.

```hcl
enable_lab1 = true    # two PII stores
enable_lab2 = true    # host VM + app + Webmin
enable_lab3 = false   # planned
enable_lab4 = false   # planned
```

### After apply

**Lab 1**

- `lab1_remediate_*` — fix (block public → reassess clear)
- `lab1_exception_*` — leave public; whitelist / accept risk

**Lab 2**

- App: `lab2_application_url` → `/labs`
- Webmin: `lab2_webmin_url` → **`admin` / `password`**
- Install the Upwind **host sensor** on `lab2_public_ip`, then generate traffic / exploits

## Layout

```
lab1-public-data/       Synthetic PII seeds (both Lab 1 buckets)
lab2-wakezone-app/      Host DVWA-lite + FiU heartbeats
lab3-kubernetes/        Planned — EKS | AKS | GKE
lab4-serverless/        Planned — Lambda | Cloud Run | App Service
infrastructure/aws|azure|gcp
docs/LEARNING-PATH.md   Portal module mapping
docs/SA-ONBOARDING.md   Facilitator runbook
scripts/                VM install (app + Webmin) — no Upwind
```

## Safety

- Not for production. All vulns and exposures are intentional.
- One cloud per SA; destroy when the session ends.
- Synthetic PII only (dlptest-style patterns).
