# AWS stack 3/3 — EKS (Lab 5)

```bash
cd infrastructure/aws/lab5-kubernetes
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output
```

Deploys Flask CVE demo (public `python:3.9-bullseye`) behind a LoadBalancer Service.  
**Destroy promptly.** Install the Upwind cluster/node sensor yourself.
