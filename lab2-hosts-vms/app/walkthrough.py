"""Per-attack walkthrough copy for Lab 2 — shown in /walkthrough and each /labs page."""

from __future__ import annotations

PREAMBLE = {
    "title": "Lab 2 walkthrough — VM and Hosts",
    "intro": (
        "Use this page while you work. Install the Upwind host sensor first, "
        "let it baseline, then run each attack below. FiU modules need the sensor "
        "for Function-in-use; classic AppSec + Webmin feed Threats / Stories."
    ),
    "order": [
        "Shell onto this VM (AWS SSM / Azure SSH / GCP gcloud compute ssh).",
        "Install the Upwind host eBPF sensor from the console/portal.",
        "Wait until the host appears and L3 / L4 / L7 baseline looks healthy.",
        "Run FiU modules (Pillow, Brotli, YAML, tarfile) → Vuln Management → Function in use.",
        "Run SQLi, path traversal, command injection, secrets, Webmin → Threats / Stories.",
        "When finished: terraform destroy in infrastructure/<cloud>/lab1-3.",
    ],
}

# Keys match LABS[].slug in main.py
ATTACKS: dict[str, dict] = {
    "fiu-pillow-imagemath": {
        "goal": "Trigger Pillow ImageMath.eval (CVE-2023-50447) for Function-in-use.",
        "upwind": "Vuln Management → Function in use → look for ImageMath / Pillow.",
        "steps": [
            "Open this lab page (form is pre-filled with a demo RCE expression).",
            "Click POST /api/board/preview (or leave the default expression).",
            "Confirm JSON result shows the call ran (ok / error still exercises the function).",
            "Optional: on the host, check /tmp/jwz-cve-2023-50447-id.txt if the payload succeeded.",
            "In Upwind, refresh Function in use for this CVE / package.",
        ],
        "payload": "__import__('os').system('id > /tmp/jwz-cve-2023-50447-id.txt')",
    },
    "fiu-pillow-jpeg": {
        "goal": "Hit Pillow JPEG thumbnail path (CVE-2026-112403) for FiU.",
        "upwind": "Function in use → Pillow / ImagingJpegDecode-related finding.",
        "steps": [
            "Heartbeat already thumbnails a JPEG every 60s (baseline FiU).",
            "To exercise via HTTP: upload any .jpg and click POST /api/image/thumbnail.",
            "Confirm JSON result returns.",
            "Check Function in use after a minute if NRT is slow.",
        ],
        "payload": "Any JPEG file upload",
    },
    "fiu-pillow-eps": {
        "goal": "Open EPS through Pillow → Ghostscript (CVE-2026-112900).",
        "upwind": "Function in use → EPS / Ghostscript-related Pillow path.",
        "steps": [
            "Heartbeat opens a benign EPS on a timer.",
            "Click POST /api/image/eps with the default filename, or try a crafted name.",
            "Injection primitive: filenames starting with - or @ (Ghostscript args).",
            "Confirm response, then check Function in use.",
        ],
        "payload": "/tmp/jwz-fiu/benign.eps",
    },
    "fiu-brotli": {
        "goal": "Call brotli.decompress (CVE-2026-111497 / HTTP2Shell path).",
        "upwind": "Function in use → brotli / DecodeBlockTypeAndLength.",
        "steps": [
            "Heartbeat already decompresses a sample every 60s.",
            "On this page, paste base64 Brotli (or use a sample from the Result panel) and POST.",
            "Confirm JSON result, then check Function in use.",
        ],
        "payload": "Base64 brotli bytes in the form",
    },
    "fiu-yaml": {
        "goal": "Unsafe yaml.load (CVE-2020-14343) for FiU + possible RCE file drop.",
        "upwind": "Function in use → PyYAML; optional host file evidence under /tmp.",
        "steps": [
            "Leave the default !!python/object/apply:os.system payload (or paste your own).",
            "Click POST /api/checkout.",
            "Optional: on the host, ls /tmp/jwz-cve-2020-14343-id.txt",
            "Check Function in use for PyYAML.",
        ],
        "payload": "!!python/object/apply:os.system ['id > /tmp/jwz-cve-2020-14343-id.txt']",
    },
    "fiu-tarfile": {
        "goal": "TarFile.extractall without filter (CVE-2007-4559).",
        "upwind": "Function in use → tarfile / extractall.",
        "steps": [
            "Heartbeat extracts a benign tar on a timer.",
            "Upload a .tar / .tar.gz (optionally with ../ traversal members) and POST.",
            "Confirm JSON result, then check Function in use.",
        ],
        "payload": "Tar archive upload (optional path traversal members)",
    },
    "sqli-login": {
        "goal": "Bypass login with classic SQLi → auth story / AppSec signal.",
        "upwind": "Threats / Stories / runtime map around the Wake Zone process.",
        "steps": [
            "Open /login (or use the link on this lab page).",
            "Normal login: jordan.lee@example.com / jordanwaves",
            "Bypass: email  ' OR '1'='1   password  anything",
            "You should land signed-in on /labs.",
            "In Upwind, look for related detections / process activity.",
        ],
        "payload": "email: ' OR '1'='1   password: anything",
    },
    "path-traversal": {
        "goal": "Read a file outside public/ via ../",
        "upwind": "File read / sensitive data access signals if instrumented.",
        "steps": [
            "Submit name=welcome.txt (benign).",
            "Submit name=../secret.txt to escape into demo-secrets/.",
            "Result panel should show the synthetic secret content.",
        ],
        "payload": "../secret.txt",
    },
    "cmd-injection": {
        "goal": "Inject a shell metacharacter into the ping helper.",
        "upwind": "Threats / Stories — suspicious process / command execution.",
        "steps": [
            "Submit host=127.0.0.1 (benign ping).",
            "Submit host=127.0.0.1; id  (or 127.0.0.1 && whoami).",
            "Result stdout/stderr should show id/whoami output.",
            "Correlate in Upwind Threats / runtime map.",
        ],
        "payload": "127.0.0.1; id",
    },
    "secrets": {
        "goal": "Show hardcoded demo cloud keys / DB password in env.",
        "upwind": "Secrets / sensitive data posture if scanned; awareness for demos.",
        "steps": [
            "Open this page — Result panel lists JWZ_DEMO_* env vars.",
            "Note these are synthetic workshop values only.",
            "Optionally show in a customer conversation as 'secrets on disk/env'.",
        ],
        "payload": "N/A — page displays env",
    },
    "webmin": {
        "goal": "Log into exposed Webmin as admin → full host compromise story.",
        "upwind": "Exposed management / lateral movement / privileged session stories.",
        "steps": [
            "From terraform output: open lab2_webmin_url (https://<ip>:10000).",
            "Accept the self-signed TLS warning.",
            "Login admin / password.",
            "You now have a Linux admin UI on the host — classic exposed mgmt plane.",
            "In Upwind, look for exposed service / threat stories around :10000.",
        ],
        "payload": "admin / password @ :10000",
    },
}


def for_slug(slug: str) -> dict | None:
    return ATTACKS.get(slug)
