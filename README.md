<h1 align="center">Jay's Wake Zone</h1>

<p align="center">
  <strong>Grab-and-go</strong> SA Surf School labs — fork, clone, <code>terraform apply</code>.
  No image builds. You install Upwind sensors yourself.
</p>

<p align="center">
  <a href="https://github.com/AstralJays/JaysWakeZone"><img src="https://img.shields.io/badge/org-AstralJays-24292f.svg?logo=github" alt="AstralJays" /></a>
  <img src="https://img.shields.io/badge/cloud-AWS%20%7C%20Azure%20%7C%20GCP-success.svg" alt="Clouds" />
  <img src="https://img.shields.io/badge/stacks-lab1--3%20%7C%20lab4%20%7C%20lab5-informational.svg" alt="Stacks" />
</p>

---

> [!CAUTION]
> **Intentionally vulnerable — do not use in production.**  
> Sandbox accounts only. Destroy each stack when finished — especially Lab 5.

## Infrastructure layout (one cloud → three applies)

```text
infrastructure/<aws|azure|gcp>/
  lab1-3/              ← Labs 1 + 2 + 3 (day-1)
  lab4-containers/     ← Lab 4 only
  lab5-kubernetes/     ← Lab 5 only
```

| Folder | Labs | What you get |
|--------|------|--------------|
| `lab1-3/` | **1** Storage · **2** VM and Hosts · **3** Serverless | Day-1 onboarding |
| `lab4-containers/` | **4** Juice Shop (public image) | ECS Fargate \| ACA \| Cloud Run |
| `lab5-kubernetes/` | **5** Kubernetes | EKS \| AKS \| GKE |

Each folder is its **own** Terraform state — apply/destroy independently.

## Grab and go (Lab 1–3)

```bash
git clone https://github.com/<YOU>/JaysWakeZone.git
cd JaysWakeZone/infrastructure/aws/lab1-3   # or azure|gcp
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply && terraform output
```

Azure: set `ssh_public_key` (needed for Lab 2 sensor install). GCP: set `project_id`.

**Lab 2 shell (Upwind host sensor):** AWS uses **SSM by default** (`terraform output lab2_ssm_command`). Azure/GCP use SSH / `gcloud compute ssh`. Details: [docs/HOST-ACCESS.md](docs/HOST-ACCESS.md).

## Later labs

```bash
cd infrastructure/<cloud>/lab4-containers
terraform init && terraform apply   # → lab4_url

cd infrastructure/<cloud>/lab5-kubernetes
terraform init && terraform apply   # → lab5_url  (destroy ASAP)
```

## Apps in the repo

| Lab | Code |
|-----|------|
| 1 | `lab1-public-data/` |
| 2 | `lab2-hosts-vms/` |
| 3 | `lab3-serverless/` |
| 4 | `lab4-containers/` (Juice Shop image) |
| 5 | `lab5-kubernetes/` |

Public Docker Hub only for container/K8s workloads — no ECR/ACR/GAR.

## Cost hygiene

- Day-1 = **`lab1-3/` only**.
- Lab 4 AWS includes an ALB — destroy when done.
- Lab 5 = control plane + node — never leave overnight without intent.

## Before labs

Connect the sandbox cloud in Upwind (CSPM · agentless · DSPM · activity logs / CDR).

[docs/LEARNING-PATH.md](docs/LEARNING-PATH.md) · [docs/SA-ONBOARDING.md](docs/SA-ONBOARDING.md)
