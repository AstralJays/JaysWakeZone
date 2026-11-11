# Jay's Wake Zone

SA onboarding labs for [AstralJays](https://github.com/AstralJays) — two simple, intentionally vulnerable exercises you can stand up in **AWS**, **Azure**, or **GCP**.

> [!CAUTION]
> **Do not deploy to production accounts.** Keep sandboxes ephemeral. All PII in this repo is synthetic.

## Labs

| Lab | Story | What Upwind / CSPM should light up |
|-----|-------|--------------------------------------|
| **1 — Public bucket** | Object storage left world-readable with customer / PCI-style exports | Public storage, sensitive data exposure |
| **2 — Wake Zone app** | Modern DVWA-style wakeboard shop (SQLi, path traversal, command injection, secrets) | Runtime vulns, attack paths, host/container findings |

Lab 1 data shapes follow common DLP test sets such as [dlptest.com/sample-data](https://dlptest.com/sample-data/). Lab 2 is a purposeful, lighter successor to [TraditionalJay](https://github.com/AstralJays/TraditionalJay) (no Log4Shell / attacker box).

## Pick a cloud

Each folder is standalone Terraform. Defaults enable **both** labs.

```bash
# AWS
cd infrastructure/aws && cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output

# Azure
cd infrastructure/azure && cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
terraform output

# GCP
cd infrastructure/gcp && cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply -var="project_id=YOUR_PROJECT"
terraform output
```

Toggle labs with:

```hcl
enable_lab1 = true
enable_lab2 = true
```

## Local Lab 2 (no cloud)

```bash
cd lab2-wakezone-app
docker compose up --build
# open http://localhost:8080/labs
```

## Layout

```
lab1-public-data/          Synthetic CSV/JSON PII seeds
lab2-wakezone-app/         FastAPI DVWA-lite + Dockerfile
infrastructure/aws|azure|gcp
docs/SA-ONBOARDING.md      Facilitator runbook
scripts/install-app.sh     Cloud-init installer for Lab 2
```

## Safety

- Public storage and open security groups are intentional for the lab.
- Tighten `*_ingress_cidr` / source ranges for shared workshops.
- Tear down with `terraform destroy` when finished.
