# Lab 2 — Host VM (eBPF sensor + DVWA-lite)

Linux host with:

- **Wake Zone app** (`:8080/labs`) — FiU heartbeats + classic attack modules  
- **Webmin** (`:10000`) — `admin` / `password`

## SA steps

1. Terraform creates the VM (this app + Webmin).  
2. **You** install the Upwind **host sensor** (eBPF) — not automated here.  
3. Let the sensor baseline L3 / L4 / L7.  
4. Run attacks from `/labs` and Webmin to generate detections / stories.  
5. Check **Function in use** on the heartbeated CVEs.

This repo never deploys Upwind.
