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

You never build or push container images. Terraform pulls public bases / packages zip Lambdas for you.  
**Upwind is not in this repo** — connect the account and install sensors/tracers after apply.

### AWS

```bash
git clone https://github.com/<YOU>/JaysWakeZone.git
cd JaysWakeZone/infrastructure/aws
cp terraform.tfvars.example terraform.tfvars
# edit only if you need a non-default region/profile
terraform init
terraform apply
terraform output
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

Defaults ship **Labs 1 + 2 + 4** in that one apply. Lab 3 (K8s) stays off.

If you changed Lab 2 app code in your fork, set `repo_url` in tfvars to your fork URL. Otherwise leave the default.

## What you get

| Lab | Terraform creates | You do after apply |
|-----|-------------------|--------------------|
| **1** Storage | Two public PII stores | CSPM loop: fix one, risk-accept the other |
| **2** Host | VM + DVWA-lite + Webmin | Install **host eBPF sensor**, run `/labs` attacks |
| **4** Serverless | Lambda / App Service / Cloud Run | Install **tracer**, hit the URL |
| **3** K8s | — (later) | Keep `enable_lab3 = false` for now |

### Useful outputs

- Lab 1: `lab1_remediate_*` · `lab1_exception_*`
- Lab 2: `lab2_application_url` · `lab2_webmin_url` (`admin` / `password`) · `lab2_public_ip`
- Lab 4: `lab4_function_url` (AWS) · `lab4_app_url` (Azure) · `lab4_service_url` (GCP)

## Before labs — connect the account

In Upwind, connect the sandbox cloud so CSPM, agentless, DSPM, and activity logs / CDR are on.  
Then apply. Then sensors.

More detail: [docs/LEARNING-PATH.md](docs/LEARNING-PATH.md) · Facilitator: [docs/SA-ONBOARDING.md](docs/SA-ONBOARDING.md)

## Safety

- Not for production.
- One cloud per SA.
- Destroy when the session ends.
