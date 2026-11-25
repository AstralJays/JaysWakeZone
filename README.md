<h1 align="center">Jay's Wake Zone</h1>

<p align="center">
  <strong>Grab-and-go</strong> SA Surf School labs — fork, clone, <code>terraform apply</code>.
  No image builds for Labs 1–4. You install Upwind sensors yourself.
</p>

<p align="center">
  <a href="https://github.com/AstralJays/JaysWakeZone"><img src="https://img.shields.io/badge/org-AstralJays-24292f.svg?logo=github" alt="AstralJays" /></a>
  <img src="https://img.shields.io/badge/cloud-AWS%20%7C%20Azure%20%7C%20GCP-success.svg" alt="Clouds" />
  <img src="https://img.shields.io/badge/labs-Lab1--3%20%7C%20Lab4%20%7C%20Lab5-informational.svg" alt="Labs" />
</p>

---

> [!CAUTION]
> **Intentionally vulnerable — do not use in production.**  
> Sandbox accounts only. Destroy each stack when finished — especially Lab 5 (GPU).

## Repo layout (three labs)

```text
Lab1-3/     Storage · VM · Serverless
Lab4/       Abstracted container services (Juice Shop)
Lab5/       Microservice + AI (Wakezone AI + Ollama GPU)
docs/       SA notes
```

Each lab has its own `infrastructure/{aws|azure|gcp}/` — separate Terraform state.

| Folder | What you get |
|--------|----------------|
| `Lab1-3/` | **1** Storage · **2** VM/Hosts · **3** Serverless |
| `Lab4/` | Juice Shop on ECS Fargate \| ACA \| Cloud Run |
| `Lab5/` | Wakezone AI + in-cluster Ollama on GPU (EKS \| AKS \| GKE) |

## Grab and go

```bash
git clone https://github.com/<YOU>/JaysWakeZone.git
cd JaysWakeZone/Lab1-3/infrastructure/aws   # or azure|gcp
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

```bash
cd Lab4/infrastructure/<cloud>
terraform init && terraform apply   # → lab4_url
```

```bash
# publish Wakezone AI image first
cd Lab5
docker build -t YOURUSER/jwz-agent-lab:0.1.0 .
docker push YOURUSER/jwz-agent-lab:0.1.0

cd infrastructure/<cloud>
# set container_image in terraform.tfvars
terraform init && terraform apply   # → lab5_url  (destroy ASAP)
```

Upwind sensors/tracers are **not** in Terraform — install yourself after apply. Lab 5 nodes are sized for sensor headroom.

See [docs/SA-ONBOARDING.md](docs/SA-ONBOARDING.md).
