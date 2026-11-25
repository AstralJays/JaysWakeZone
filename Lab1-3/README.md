# Lab 1–3 — Storage · VM · Serverless

One Terraform apply per cloud deploys **all three** labs (separate state from Lab 4 / Lab 5).

| Lab | Folder | What |
|-----|--------|------|
| **1** Storage | `lab1-public-data/` | Public buckets + synthetic PII (CSPM / DSPM) |
| **2** VM/Hosts | `lab2-hosts-vms/` | DVWA-lite app + Webmin on a VM |
| **3** Serverless | `lab3-serverless/` | Lambda / App Service / Cloud Run |

## Configure

```bash
cd Lab1-3/infrastructure/<aws|azure|gcp>
cp terraform.tfvars.example terraform.tfvars
```

| Cloud | Edit in `terraform.tfvars` |
|-------|----------------------------|
| **AWS** | `aws_region` (default `us-east-1`). Optional: `aws_profile`, `key_name` (SSM is default — no key). |
| **Azure** | `location` (default `eastus`). **Required:** `ssh_public_key` for the Lab 2 VM. |
| **GCP** | **Required:** `project_id`. Optional: `region` / `zone`. |

`repo_url` / `repo_ref` default to this GitHub repo (`main`) so the VM can clone Lab 2. Leave them unless you fork.

## Deploy

```bash
terraform init
terraform apply
terraform output
```

Useful outputs: `lab1_*` (bucket names), `lab2_*` (app URL / SSM or SSH), `lab3_*` (function URL).

**Lab 2 shell** (install Upwind host sensor yourself — not in Terraform):

| Cloud | Access |
|-------|--------|
| AWS | `terraform output lab2_ssm_command` → SSM (default; no key). Optional `key_name` for SSH. Wait ~2 min after boot for SSM. |
| Azure | `terraform output lab2_ssh_command` (requires `ssh_public_key` in tfvars) |
| GCP | `terraform output lab2_ssh_command` (`gcloud compute ssh`) |

## Destroy

```bash
# same folder as apply
terraform destroy
```

## After apply (Upwind)

Install sensors yourself — not in Terraform:

1. Lab 1 — agentless / CSPM on the public buckets  
2. Lab 2 — host eBPF sensor on the VM, then use `/walkthrough`  
3. Lab 3 — tracer on the serverless URL  

More detail: `lab1-public-data/README.md`, `lab2-hosts-vms/WALKTHROUGH.md`, `lab3-serverless/README.md`.
