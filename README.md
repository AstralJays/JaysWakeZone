<h1 align="center">Jay's Wake Zone</h1>

<p align="center">
  SA onboarding labs — two simple, intentionally vulnerable exercises you can stand up in <strong>AWS</strong>, <strong>Azure</strong>, or <strong>GCP</strong>.
</p>

<p align="center">
  <a href="https://github.com/AstralJays/JaysWakeZone"><img src="https://img.shields.io/badge/org-AstralJays-24292f.svg?logo=github" alt="AstralJays" /></a>
  <img src="https://img.shields.io/badge/labs-2-informational.svg" alt="Labs" />
  <img src="https://img.shields.io/badge/cloud-AWS%20%7C%20Azure%20%7C%20GCP-success.svg" alt="Clouds" />
  <img src="https://img.shields.io/badge/iac-Terraform-7B42BC.svg?logo=terraform&logoColor=white" alt="Terraform" />
  <img src="https://img.shields.io/badge/status-Workshop-orange.svg" alt="Status" />
</p>

---

> [!CAUTION]
> **Intentionally vulnerable — do not use in production.**  
> This repository ships exploitable CVEs, public object storage with synthetic PII, open security groups, and Webmin with weak credentials (`admin` / `password`).  
> Deploy only in ephemeral **sandbox / workshop** cloud accounts. Tear down with `terraform destroy` when finished. Never point this at production tenants, real customer data, or shared corp networks.

**Repository:** [AstralJays/JaysWakeZone](https://github.com/AstralJays/JaysWakeZone)  
**Related:** [TraditionalJay](https://github.com/AstralJays/TraditionalJay) · [JaysSurfShop](https://github.com/AstralJays/JaysSurfShop) · [dlptest.com sample data](https://dlptest.com/sample-data/)

## Labs

| Lab | Story | What should light up |
|-----|-------|----------------------|
| **1 — Public bucket** | Object storage left world-readable with customer / PCI-style exports | Public storage, sensitive data exposure |
| **2 — Wake Zone app** | DVWA-style shop with **six Function-in-use CVEs** + classic AppSec + **Webmin on :10000** (`admin` / `password`) | Runtime exploit CVEs, FiU, exposed mgmt plane |

Lab 2 is a purposeful, lighter successor to TraditionalJay (no Log4Shell / attacker box).

## Quick start

Pick **one** cloud. Defaults enable **both** labs. Requires Terraform `>= 1.5` and a cloud CLI (`aws` / `az` / `gcloud`).

### 1. Clone

```bash
git clone https://github.com/AstralJays/JaysWakeZone.git
cd JaysWakeZone
```

### 2. Deploy (choose one)

**AWS**

```bash
cd infrastructure/aws
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output
```

**Azure**

```bash
cd infrastructure/azure
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
terraform output
```

**GCP**

```bash
cd infrastructure/gcp
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply -var="project_id=YOUR_PROJECT"
terraform output
```

Toggle labs in `terraform.tfvars`:

```hcl
enable_lab1 = true
enable_lab2 = true
```

### 3. Run the labs

1. Open `lab1_public_url` / list the public bucket — download a CSV or `customers.json`
2. Open `lab2_application_url` → `/labs` — walk SQLi, path traversal, command injection, YAML, secrets
3. Tear down when finished: `terraform destroy`

**Next:** facilitator runbook → **[SA onboarding](docs/SA-ONBOARDING.md)**

## Local Lab 2 (no cloud)

```bash
cd lab2-wakezone-app
docker compose up --build
# open http://localhost:8080/labs
```

## Documentation

| | |
|--|--|
| [SA onboarding](docs/SA-ONBOARDING.md) | Facilitator timeline, Lab 1/2 walkthrough, teardown |
| [Lab 1 data](lab1-public-data/README.md) | Synthetic CSV/JSON PII seeds (dlptest-style) |
| [AWS Terraform](infrastructure/aws/) | Public S3 + EC2 DVWA-lite |
| [Azure Terraform](infrastructure/azure/) | Public Blob + VM DVWA-lite |
| [GCP Terraform](infrastructure/gcp/) | Public GCS + GCE DVWA-lite |

## Layout

```
lab1-public-data/          Synthetic CSV/JSON PII seeds
lab2-wakezone-app/         FastAPI DVWA-lite + Dockerfile
infrastructure/aws|azure|gcp
docs/SA-ONBOARDING.md      Facilitator runbook
scripts/install-app.sh     Cloud-init installer for Lab 2
```

## Safety

- **Not for production.** Every intentional vuln, public bucket, open SG, and Webmin login is by design.
- Public storage and `0.0.0.0/0` ingress are intentional — tighten `*_ingress_cidr` only for shared workshops
- Webmin: `https://<ip>:10000` with **`admin` / `password`** (sudo on the host)
- All Lab 1 PII is synthetic
- Tear down with `terraform destroy` when finished

## Feedback

Bugs and lab ideas: [open an issue](https://github.com/AstralJays/JaysWakeZone/issues) on this repo.
