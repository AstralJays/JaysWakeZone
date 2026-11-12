# Lab 2 — VM and Hosts walkthrough

Same steps are shown in the app at **`/walkthrough`** (and summarized on `/labs`).

## Before you attack

1. Connect the cloud account in Upwind (CSPM / agentless / DSPM / activity logs).
2. Deploy `infrastructure/<cloud>/lab1-3` and open `lab2_application_url`.
3. Get a shell on the VM ([HOST-ACCESS.md](../docs/HOST-ACCESS.md)).
4. Install the **Upwind host sensor** (eBPF). Wait for the host to appear and baseline **L3 / L4 / L7**.

## Then generate signal

| Order | What | Where | Look for in Upwind |
|-------|------|--------|--------------------|
| 1 | FiU CVEs (Pillow, Brotli, PyYAML, tarfile) | `/labs` → FiU modules | Function in use / vuln runtime |
| 2 | SQLi login | `/login` or SQLi lab | App / threat stories if instrumented |
| 3 | Path traversal / cmd injection | Matching lab cards | Runtime detections |
| 4 | Webmin | `lab2_webmin_url` → `admin` / `password` | Exposed mgmt / host compromise path |

## Demo accounts

```
jordan.lee@example.com / jordanwaves
sam.nguyen@example.com / samwaves
admin@jayswakezone.example / staffadmin

SQLi bypass: email  ' OR '1'='1   password  anything
```

## Done

When finished: `terraform destroy` in `lab1-3`. Do not leave the public VM up.
