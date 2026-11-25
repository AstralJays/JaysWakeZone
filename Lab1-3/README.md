# Lab 1–3 — Storage · VM · Serverless

**One deployment** — a single `terraform apply` per cloud stands up all three tracks (one state, one destroy). Separate from Lab 4 / Lab 5.

| Track | Folder | What |
|-------|--------|------|
| **1** Storage | `data/` | Public buckets + synthetic PII and fake secrets (CSPM / DSPM) |
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

You **will need a shell on the Lab 2 VM** (SSM, OpenSSH, or PuTTY) to install the Upwind host sensor. Set that up before or during configure — see [Shell into the host VM](#shell-into-the-host-vm).

## Configure

```bash
cd Lab1-3/infrastructure/<aws|azure|gcp>
cp terraform.tfvars.example terraform.tfvars
```

| Cloud | Edit in `terraform.tfvars` |
|-------|----------------------------|
| **AWS** | `aws_region` (default `us-east-1`). Optional: `aws_profile`. For SSH/PuTTY (not only SSM): set `key_name` to an existing EC2 key pair. |
| **Azure** | `location` (default `eastus`). **Required:** `ssh_public_key` (see key gen below). |
| **GCP** | **Required:** `project_id`. Optional: `region` / `zone`. Optional: `ssh_public_key` for plain `ssh` in addition to `gcloud compute ssh`. |

### Generate an SSH key (Azure required; also fine for GCP / local use)

```bash
ssh-keygen -t ed25519 -f ~/.ssh/jwz_lab -N "" -C "jayswakezone"
cat ~/.ssh/jwz_lab.pub
# macOS: pbcopy < ~/.ssh/jwz_lab.pub
```

**Azure** — paste the **public** key into `infrastructure/azure/terraform.tfvars`:

```hcl
ssh_public_key = "ssh-ed25519 AAAA... jayswakezone"
```

**AWS SSH/PuTTY** — create (or reuse) an EC2 key pair in the console / CLI, download the `.pem`, set:

```hcl
key_name = "my-ec2-keypair"   # name in AWS, not the file path
```

Keep the private key (`.pem` / `.ppk`) on the machine you’ll SSH from.

`repo_url` / `repo_ref` default to this GitHub repo (`main`) so the VM can clone `host/`. Leave them unless you fork.

## Deploy

```bash
terraform init
terraform apply
terraform output
```

Useful outputs: `lab1_*` (buckets), `lab2_*` (app URL / shell hints), `lab3_*` (function URL).

## Shell into the host VM

Needed for the **Upwind host sensor**. Pick what your workshop machines support.

### AWS — SSM (default, no SSH key)

Needs Session Manager plugin + IAM (already on the instance). Wait ~2 minutes after boot:

```bash
terraform output lab2_ssm_command
# → aws ssm start-session --target i-xxxx --region us-east-1
```

Works from AWS CLI on Mac/Linux/Windows. No PuTTY required.

### AWS — SSH / PuTTY (optional)

Set `key_name` before apply. Then:

```bash
terraform output lab2_public_ip
ssh -i /path/to/keypair.pem ubuntu@<lab2_public_ip>
```

**PuTTY:** convert `.pem` → `.ppk` with PuTTYgen → Session host `ubuntu@<ip>` (or IP + username `ubuntu`) → Auth → private key `.ppk`.

### Azure — SSH / PuTTY (required key at apply)

```bash
terraform output lab2_ssh_command
ssh -i ~/.ssh/jwz_lab azureuser@<lab2_public_ip>
```

**PuTTY:** load `jwz_lab` into PuTTYgen (Conversions → Import) → save `.ppk` → connect as `azureuser` with that key.

### GCP — gcloud or SSH

```bash
terraform output lab2_ssh_command
# → gcloud compute ssh ubuntu@… --zone … --project …
```

Or plain SSH if you set `ssh_public_key` in tfvars:

```bash
ssh -i ~/.ssh/jwz_lab ubuntu@<lab2_public_ip>
```

## Destroy

```bash
# same folder as apply
terraform destroy
```

## After apply (Upwind)

Install sensors yourself — not in Terraform:

1. Storage — agentless / CSPM on the public buckets  
2. Host — shell in (above) → host eBPF sensor → `/walkthrough` on the app URL  
3. Serverless — tracer on the function URL  

More detail: `data/README.md`, `host/WALKTHROUGH.md`, `serverless/README.md`.
