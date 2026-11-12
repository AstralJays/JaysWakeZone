# SA Onboarding — facilitator runbook

## Day-1 (stack 1)

```bash
cd infrastructure/<aws|azure|gcp>/labs-1-3
cp terraform.tfvars.example terraform.tfvars
terraform init && apply && output
# Lab 1 CSPM → Lab 2 host sensor → Lab 3 tracer
terraform destroy
```

## Later — containers (stack 2)

```bash
cd infrastructure/<cloud>/containers
terraform init && apply
# output lab4_url → install tracer
terraform destroy
```

## Later — Kubernetes (stack 3)

```bash
cd infrastructure/<cloud>/kubernetes
terraform init && apply
# output lab5_url → install cluster sensor
terraform destroy   # do not leave up
```

## Outputs

| Stack | Key outputs |
|-------|-------------|
| 1 | `lab1_*` · `lab2_*` · `lab3_*` |
| 2 | `lab4_url` |
| 3 | `lab5_url` · cluster name / kubeconfig hint |
