<h1 align="center">Jay's Wake Zone</h1>

<p align="center">
  <strong>Grab-and-go</strong> SA Surf School labs — fork, clone, <code>terraform apply</code>.
  No image builds. You install Upwind sensors yourself.
</p>

<p align="center">
  <a href="https://github.com/AstralJays/JaysWakeZone"><img src="https://img.shields.io/badge/org-AstralJays-24292f.svg?logo=github" alt="AstralJays" /></a>
  <img src="https://img.shields.io/badge/cloud-AWS%20%7C%20Azure%20%7C%20GCP-success.svg" alt="Clouds" />
  <img src="https://img.shields.io/badge/stacks-3%20per%20cloud-informational.svg" alt="Stacks" />
</p>

---

> [!CAUTION]
> **Intentionally vulnerable — do not use in production.**  
> Sandbox accounts only. Destroy each stack when finished.

## Three independent Terraform stacks (per cloud)

Pick **one** cloud. Each folder is its **own** state — apply / destroy separately (cost control).

| Stack | Path | What’s in it | When |
|-------|------|--------------|------|
| **1 — Labs 1–3** | `infrastructure/<cloud>/labs-1-3/` | Storage · VM and Hosts · Serverless | Onboarding day |
| **2 — Containers** | `infrastructure/<cloud>/containers/` | ECS Fargate \| Azure Container Apps | Later track |
| **3 — Kubernetes** | `infrastructure/<cloud>/kubernetes/` | EKS \| AKS \| GKE | Last / most expensive |

```text
infrastructure/
  aws|azure|gcp/
    labs-1-3/      ← day-1 grab-and-go
    containers/    ← planned (independent apply)
    kubernetes/    ← planned (independent apply)
```

## Grab and go (stack 1 only)

```text
1. Fork AstralJays/JaysWakeZone
2. Clone your fork
3. Pick one cloud
4. cd infrastructure/<cloud>/labs-1-3
5. terraform init && terraform apply && terraform output
6. Install sensors/tracers in Upwind
7. terraform destroy   # this stack only
```

### AWS

```bash
cd infrastructure/aws/labs-1-3
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply && terraform output
```

### Azure

```bash
cd infrastructure/azure/labs-1-3
cp terraform.tfvars.example terraform.tfvars
# set ssh_public_key
terraform init && terraform apply && terraform output
```

### GCP

```bash
cd infrastructure/gcp/labs-1-3
cp terraform.tfvars.example terraform.tfvars
# set project_id
terraform init && terraform apply && terraform output
```

## Labs in stack 1

| Lab | Creates | You do after apply |
|-----|---------|--------------------|
| **1** Storage | Two public PII stores | CSPM: fix one, risk-accept the other |
| **2** VM and Hosts | Linux VM + DVWA-lite + Webmin | Host eBPF sensor + `/labs` attacks |
| **3** Serverless | Lambda / App Service / Cloud Run | Tracer + hit URL |

Outputs: `lab1_*` · `lab2_*` · `lab3_*`

## Cost hygiene

- Day-1 = **stack 1 only**. Leave `containers/` and `kubernetes/` alone until needed.
- Destroy stack 1 before (or instead of) standing up stack 2/3 if you are spend-sensitive.
- Each stack destroys independently — no shared enable flags.

## Before labs

Connect the sandbox cloud in Upwind (CSPM · agentless · DSPM · activity logs / CDR).

[docs/LEARNING-PATH.md](docs/LEARNING-PATH.md) · [docs/SA-ONBOARDING.md](docs/SA-ONBOARDING.md)
