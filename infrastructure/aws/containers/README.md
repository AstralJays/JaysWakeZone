# AWS stack 2/3 — ECS Fargate (Lab 4)

```bash
cd infrastructure/aws/containers
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output lab4_url
```

Public `python:3.9-bullseye` + boot script (no ECR). Uses **default VPC** (no NAT).  
**ALB has hourly cost** — `terraform destroy` when finished. Install Upwind tracer yourself.
