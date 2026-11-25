# Lab 1–3 — Storage · VM · Serverless

**One deployment** — a single `terraform apply` per cloud stands up all three tracks (one state, one destroy). Separate from Lab 4 / Lab 5.

| Track | Folder | What |
|-------|--------|------|
| **1** Storage | `data/` | Public buckets + synthetic PII (CSPM / DSPM) |
| **2** VM/Hosts | `host/` | DVWA-lite app + Webmin on a VM |
| **3** Serverless | `serverless/` | Lambda / App Service / Cloud Run |

```text
Lab1-3/
  data/             seed files for storage
  host/             VM app + walkthrough
  serverless/       function code
  scripts/          VM bootstrap
  infrastructure/   aws | azure | gcp
```

## Configure

```bash
cd Lab1-3/infrastructure/<aws|azure|gcp>
cp terraform.tfvars.example terraform.tfvars
```

| Cloud | Edit in `terraform.tfvars` |
|-------|----------------------------|
| **AWS** | `aws_region` (default `us-east-1`). Optional: `aws_profile`, `key_name` (SSM is default — no key). |
| **Azure** | `location` (default `eastus`). **Required:** `ssh_public_key` for the VM. |
| **GCP** | **Required:** `project_id`. Optional: `region` / `zone`. |

`repo_url` / `repo_ref` default to this GitHub repo (`main`) so the VM can clone `host/`. Leave them unless you fork.

## Deploy

```bash
terraform init
terraform apply
terraform output
```

Useful outputs: `lab1_*` (buckets), `lab2_*` (app URL / SSM or SSH), `lab3_*` (function URL).

**VM shell** (install Upwind host sensor yourself — not in Terraform):

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

1. Storage — agentless / CSPM on the public buckets  
2. Host — eBPF sensor on the VM, then use `/walkthrough`  
3. Serverless — tracer on the function URL  

More detail: `data/README.md`, `host/WALKTHROUGH.md`, `serverless/README.md`.
