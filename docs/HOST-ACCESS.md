# Lab 2 — host access (Upwind sensor install)

Wake Zone does **not** install Upwind. After `lab1-3` apply, get a shell and run the host sensor yourself.

| Cloud | Preferred | Also |
|-------|-----------|------|
| **AWS** | **SSM Session Manager** (default) | Optional `key_name` → SSH |
| **Azure** | **SSH** (`ssh_public_key` required in tfvars) | — |
| **GCP** | **`gcloud compute ssh`** | Optional `ssh_public_key` |

## AWS

```bash
terraform output lab2_ssm_command
# → aws ssm start-session --target i-xxxx --region us-east-1
```

Needs: IAM instance profile (shipped) + SSM agent (installed in user_data).  
Wait ~2 minutes after boot for SSM to register, then:

```bash
aws ssm start-session --target "$(terraform output -raw lab2_instance_id)"
# then paste Upwind host sensor install command
```

Optional SSH: set `key_name` in tfvars to an existing EC2 key pair.

## Azure

```bash
terraform output lab2_ssh_command
ssh azureuser@<lab2_public_ip>
```

`ssh_public_key` must be set before apply.

## GCP

```bash
terraform output lab2_ssh_command
# → gcloud compute ssh ubuntu@jayswakezone-lab2 --zone ... --project ...
```

## After you’re on the box

1. Install Upwind **host sensor** (portal / console instructions).
2. Let it baseline L3/L4/L7.
3. Open `lab2_application_url` — starts on **`/walkthrough`**, then run modules on `/labs` + Webmin.

Full SA steps: [lab2-hosts-vms/WALKTHROUGH.md](../lab2-hosts-vms/WALKTHROUGH.md) (also rendered in the app).
