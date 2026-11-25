# Lab 2 — VM and Hosts

Terraform installs this for you on the Lab 2 VM. No manual app/image work.

- App: `:8080` → **`/walkthrough`** then `/labs`
- Webmin: `:10000` — `admin` / `password`

After apply: **shell onto the VM** (AWS SSM, OpenSSH, or PuTTY) → install Upwind **host sensor** → baseline L3/L4/L7 → follow the in-app walkthrough.

Shell how-to (SSM / SSH / PuTTY per cloud): parent [`../README.md`](../README.md)#shell-into-the-host-vm.  
Attacks: [WALKTHROUGH.md](WALKTHROUGH.md).

## Deploy / destroy

Use the parent stack: [`../README.md`](../README.md) (`Lab1-3/infrastructure/<cloud>/`).
