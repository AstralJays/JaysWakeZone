<h1 align="center">Jay's Wake Zone</h1>

<p align="center">
  <strong>Grab-and-go</strong> SA Surf School labs — fork, clone, <code>terraform apply</code>.
  No image builds — Labs 1–5 pull public images. You install Upwind sensors yourself.
</p>

<p align="center">
  <a href="https://github.com/AstralJays/JaysWakeZone"><img src="https://img.shields.io/badge/org-AstralJays-24292f.svg?logo=github" alt="AstralJays" /></a>
  <img src="https://img.shields.io/badge/cloud-AWS%20%7C%20Azure%20%7C%20GCP-success.svg" alt="Clouds" />
  <img src="https://img.shields.io/badge/labs-Lab1--3%20%7C%20Lab4%20%7C%20Lab5-informational.svg" alt="Labs" />
</p>

---

> [!CAUTION]
> **Intentionally vulnerable — do not use in production.**  
> Sandbox accounts only. **Destroy each stack when finished** — especially Lab 5 (GPU).

## Repo layout

```text
Lab1-3/     Storage · VM · Serverless
Lab4/       Juice Shop on managed containers
Lab5/       Wakezone AI + Ollama GPU (Kubernetes)
```

Each lab has `infrastructure/{aws|azure|gcp}/` with **its own Terraform state**. Deploy one cloud per lab folder.

| Folder | Labs | Platforms |
|--------|------|-----------|
| `Lab1-3/` | 1 Storage · 2 VM/Hosts · 3 Serverless | buckets · VM · Lambda / App Service / Cloud Run |
| `Lab4/` | Juice Shop | ECS Fargate · ACA · Cloud Run |
| `Lab5/` | Wakezone AI + Ollama | EKS · AKS · GKE |

## Before you start

1. Cloud CLI logged in (`aws`, `az`, or `gcloud`) with rights to create the lab resources.
2. Terraform installed.
3. Pick **one** cloud and stay in that cloud’s folder for that lab.

## Configure (region / project / keys)

Every stack ships a `terraform.tfvars.example`. Copy it, then edit:

```bash
cp terraform.tfvars.example terraform.tfvars
```

| Cloud | Typical edits in `terraform.tfvars` |
|-------|-------------------------------------|
| **AWS** | `aws_region` (default `us-east-1`). Optional: `aws_profile`. |
| **Azure** | `location` (default `eastus`). **Lab1-3:** set `ssh_public_key` (required for the VM). |
| **GCP** | **`project_id` (required)**. Optional: `region` / `zone` (defaults `us-central1` / `us-central1-a`). |

Lab 5 also needs **GPU quota** in that region (T4). Image defaults are public — no `container_image` unless you fork.

Full examples live next to each stack under `*/infrastructure/<cloud>/terraform.tfvars.example`.

## Deploy & destroy

Pattern is the same for every lab:

```bash
cd <Lab>/infrastructure/<aws|azure|gcp>
cp terraform.tfvars.example terraform.tfvars   # edit region / project_id / ssh key
terraform init
terraform apply
terraform output
# … use the lab, install Upwind yourself …
terraform destroy
```

### Lab1-3 (day-1)

```bash
cd Lab1-3/infrastructure/aws    # or azure|gcp
cp terraform.tfvars.example terraform.tfvars
# AWS: aws_region=…   Azure: ssh_public_key=…   GCP: project_id=…
terraform init && terraform apply
terraform output
terraform destroy
```

Outputs: `lab1_*`, `lab2_*`, `lab3_*`. Lab 2 shell: see `Lab1-3/README.md`.

### Lab 4 (Juice Shop)

```bash
cd Lab4/infrastructure/aws      # or azure|gcp
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output lab4_url
terraform destroy               # AWS ALB costs while up
```

Pulls `bkimminich/juice-shop` — no build.

### Lab 5 (Wakezone AI + GPU Ollama)

```bash
cd Lab5/infrastructure/aws      # or azure|gcp
cp terraform.tfvars.example terraform.tfvars
# confirm GPU quota; set project_id on GCP
terraform init && terraform apply
terraform output lab5_url
terraform destroy               # destroy ASAP — GPU bill
```

Pulls `papaperk/jwz-agent-lab:0.1.0` + `ollama/ollama`.

## Upwind

Sensors/tracers are **not** in Terraform — install after apply. Lab 5 nodes are sized for sensor headroom (add a GPU toleration for the cluster sensor if needed).

