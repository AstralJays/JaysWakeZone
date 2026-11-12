# Lab 5 walkthrough — DVAA on Kubernetes

## Deploy

```bash
cd infrastructure/<cloud>/lab5-kubernetes
cp terraform.tfvars.example terraform.tfvars
# GCP: set project_id
terraform init && terraform apply
terraform output lab5_url
```

Wait for the LoadBalancer, then open the DVAA dashboard.

## In the UI

1. **Agents** — browse the fleet (SecureBot → LegacyBot, MCP, A2A).
2. **Challenges / Attack Lab** — CTF-style attacks (simulated mode needs no API key).
3. **Attack Log** — review payloads and leaked secrets.

Optional LLM mode: Settings → paste OpenAI/Anthropic key (browser-side; not required for the lab).

## Upwind

Install the cluster / node sensor per portal docs, generate dashboard traffic, confirm the workload appears.

## Direct agent attacks (optional)

LB does **not** publish agent ports. After kubeconfig:

```bash
kubectl port-forward deploy/jwz-dvaa 9000:9000 7003:7003
# then e.g. npx hackmyagent attack http://localhost:7003/v1/chat/completions --api-format openai
```

## Destroy

```bash
terraform destroy
```

Do not leave the control plane overnight without intent.
