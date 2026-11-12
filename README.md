<h1 align="center">Jay's Wake Zone</h1>

<p align="center">
  <strong>Grab-and-go</strong> SA Surf School labs — fork, clone, <code>terraform apply</code>.
  No image builds. You install Upwind sensors yourself.
</p>

<p align="center">
  <a href="https://github.com/AstralJays/JaysWakeZone"><img src="https://img.shields.io/badge/org-AstralJays-24292f.svg?logo=github" alt="AstralJays" /></a>
  <img src="https://img.shields.io/badge/cloud-AWS%20%7C%20Azure%20%7C%20GCP-success.svg" alt="Clouds" />
  <img src="https://img.shields.io/badge/flow-fork%20%E2%86%92%20clone%20%E2%86%92%20tf%20apply-informational.svg" alt="Flow" />
</p>

---

> [!CAUTION]
> **Intentionally vulnerable — do not use in production.**  
> Public storage with synthetic PII, open ports, exploitable labs, Webmin (`admin` / `password`).  
> Sandbox accounts only. `terraform destroy` when finished.

## Grab and go

```text
1. Fork  →  AstralJays/JaysWakeZone  into your GitHub
2. Clone →  your fork locally
3. Pick  →  one cloud (AWS or Azure or GCP)
4. Apply →  terraform init && terraform apply
5. Use   →  terraform output  →  run labs in Upwind
6. Done  →  terraform destroy
```

You never build or push container images.  
**Upwind is not in this repo** — connect the account and install sensors/tracers after apply.

### AWS

```bash
git clone https://github.com/<YOU>/JaysWakeZone.git
cd JaysWakeZone/infrastructure/aws
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply && terraform output
```

### Azure

```bash
cd JaysWakeZone/infrastructure/azure
cp terraform.tfvars.example terraform.tfvars
# set ssh_public_key = "ssh-rsa AAAA..."
terraform init && terraform apply && terraform output
```

### GCP

```bash
cd JaysWakeZone/infrastructure/gcp
cp terraform.tfvars.example terraform.tfvars
# set project_id = "your-project"
terraform init && terraform apply && terraform output
```

**Onboarding day = Labs 1 + 2 + 3 only** (cost-minded). Labs 4–5 stay off.

## What you get

| Lab | Terraform creates | Default | You do after apply |
|-----|-------------------|---------|--------------------|
| **1** Storage | Two public PII stores | on | CSPM: fix one, risk-accept the other |
| **2** VM and Hosts | Linux VM + DVWA-lite + Webmin | on | Install **host eBPF sensor**, run `/labs` |
| **3** Serverless | Lambda / App Service / Cloud Run | on | Install **tracer**, hit the URL |
| **4** Managed containers | ECS Fargate \| Azure Container Apps | **off** | Tracer on containers *(planned)* |
| **5** Kubernetes | EKS \| AKS \| GKE | **off** | Cluster sensor *(planned)* |

### Useful outputs (Labs 1–3)

- Lab 1: `lab1_remediate_*` · `lab1_exception_*`
- Lab 2: `lab2_application_url` · `lab2_webmin_url` (`admin` / `password`) · `lab2_public_ip`
- Lab 3: `lab3_function_url` (AWS) · `lab3_app_url` (Azure) · `lab3_service_url` (GCP)

## Cost hygiene

- One cloud per SA.
- Leave `enable_lab4` / `enable_lab5` **false** unless you are on that track.
- Prefer scale-to-zero platforms when Lab 4 lands; destroy K8s promptly.
- Always `terraform destroy` when the session ends.

## Before labs — connect the account

In Upwind, connect the sandbox cloud so CSPM, agentless, DSPM, and activity logs / CDR are on.

More detail: [docs/LEARNING-PATH.md](docs/LEARNING-PATH.md) · [docs/SA-ONBOARDING.md](docs/SA-ONBOARDING.md)
