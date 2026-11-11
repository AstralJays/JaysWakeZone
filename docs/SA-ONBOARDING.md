# SA Onboarding — facilitator runbook

Aligned with **SA Surf School**: account connect → Labs 1–2 → console ops.  
Wake Zone **never** installs Upwind — the SA does CSPM / agentless / DSPM / CDR + sensors.

## Prerequisites

- Sandbox cloud account (AWS *or* Azure *or* GCP)
- Terraform `>= 1.5`, cloud CLI
- Upwind org access (SA connects the account themselves)
- Host sensor install instructions (portal: `week-1-host-sensor`)

## Timeline (~half day)

Labs **1 + 2 are one deployment** — do not split them into two applies.

| Step | Min | Activity |
|------|-----|----------|
| 0 | 15 | SA connects cloud account (CSPM, agentless, DSPM, activity logs) |
| 1 | 10 | **One** `terraform apply` → two buckets **and** Lab 2 VM/app |
| 2 | 25 | **Lab 1 CSPM loop** — remediate store A, risk-accept store B |
| 3 | 15 | SA installs **host eBPF sensor** on the Lab 2 VM |
| 4 | 30 | **Lab 2 attacks** — DVWA modules + Webmin; watch L3/L4/L7 + FiU + Stories |
| 5 | 5 | `terraform destroy` |

## Lab 1 — two-bucket CSPM / DSPM loop

Outputs: `lab1_remediate_*` and `lab1_exception_*`.

**Bucket A — remediate**

1. Confirm public listing + download a PII CSV  
2. Finding in Configurations (public storage) + DSPM (sensitive data)  
3. Block public access / remove public policy  
4. Reassess (NRT or manual) until clear  

**Bucket B — risk accept**

1. Leave public  
2. Whitelist / accept risk on that resource  
3. Reassess — exception path, not a one-way fix  

Portal: `week-4-sa-ops-asm-map`.

## Lab 2 — host sensor + DVWA

1. Open `lab2_application_url` (`/labs`)  
2. Install host sensor on `lab2_public_ip` (SA-owned step)  
3. Allow baseline, then run modules (FiU CVEs, SQLi, traversal, cmd, Webmin)  
4. Console: Function in use, Threats → Stories / Detections, runtime map  

Webmin: `lab2_webmin_url` — **`admin` / `password`**.

Portal: `week-1-host-sensor`, `week-4-sa-ops-vuln-code`, `week-4-sa-ops-threats`.

## Labs 3–4 (later)

- **Lab 3:** EKS | AKS | GKE — see `lab3-kubernetes/`  
- **Lab 4:** Lambda | Cloud Run | App Service tracer — see `lab4-serverless/`  

Keep `enable_lab3` / `enable_lab4` false until those land.

## Teardown

```bash
cd infrastructure/<cloud>
terraform destroy
```
