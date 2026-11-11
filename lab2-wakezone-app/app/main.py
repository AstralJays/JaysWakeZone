"""Jay's Wake Zone — intentional DVWA-lite for SA onboarding."""
from __future__ import annotations

import base64
import json
import os
import sqlite3
import subprocess
from pathlib import Path
from typing import Any

import yaml
from fastapi import FastAPI, Form, Query, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

APP_DIR = Path(__file__).parent
SECRETS = APP_DIR / "demo-secrets"
DB_PATH = Path("/tmp/jayswakezone.db")
SESSION_COOKIE = "jwz_session"

app = FastAPI(title="Jay's Wake Zone", version="0.1.0")
app.mount("/static", StaticFiles(directory=APP_DIR / "static"), name="static")
templates = Jinja2Templates(directory=str(APP_DIR / "templates"))

LABS = [
    {
        "slug": "sqli-login",
        "ref": "A03",
        "title": "SQL injection login",
        "blurb": "String-concat SQLite auth — classic auth bypass.",
    },
    {
        "slug": "path-traversal",
        "ref": "A01",
        "title": "Path traversal",
        "blurb": "Read files under demo-secrets via unsanitized join.",
    },
    {
        "slug": "cmd-injection",
        "ref": "A03",
        "title": "Command injection",
        "blurb": "Ping helper shells out with attacker-controlled host.",
    },
    {
        "slug": "yaml-deser",
        "ref": "CVE",
        "title": "Unsafe YAML load",
        "blurb": "PyYAML 5.3.1 unsafe_load on request body (CVE-2020-14343 class).",
    },
    {
        "slug": "secrets",
        "ref": "A07",
        "title": "Hardcoded secrets",
        "blurb": "Demo cloud keys and DB password shipped in the environment.",
    },
]


def init_db() -> None:
    conn = sqlite3.connect(DB_PATH)
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY,
          email TEXT,
          password TEXT,
          name TEXT,
          role TEXT
        )
        """
    )
    conn.execute("DELETE FROM users")
    conn.executemany(
        "INSERT INTO users (email, password, name, role) VALUES (?, ?, ?, ?)",
        [
            ("jordan.lee@example.com", "jordanwaves", "Jordan Lee", "rider"),
            ("sam.nguyen@example.com", "samwaves", "Sam Nguyen", "rider"),
            ("admin@jayswakezone.example", "staffadmin", "Wake Zone Admin", "admin"),
        ],
    )
    conn.commit()
    conn.close()


@app.on_event("startup")
def _startup() -> None:
    SECRETS.mkdir(parents=True, exist_ok=True)
    (SECRETS / "public").mkdir(parents=True, exist_ok=True)
    (SECRETS / "public" / "welcome.txt").write_text(
        "Welcome to Jay's Wake Zone — public asset.\n", encoding="utf-8"
    )
    (SECRETS / "secret.txt").write_text(
        "SYNTHETIC secret: stripe_test_sk_live_wakezone_demo_do_not_use\n",
        encoding="utf-8",
    )
    init_db()


def _encode_session(user: dict) -> str:
    return base64.urlsafe_b64encode(json.dumps(user).encode()).decode().rstrip("=")


def _decode_session(raw: str | None) -> dict | None:
    if not raw:
        return None
    try:
        pad = "=" * (-len(raw) % 4)
        data = json.loads(base64.urlsafe_b64decode(raw + pad))
        if data.get("email") and data.get("name"):
            return data
    except Exception:
        return None
    return None


def _user(request: Request) -> dict | None:
    return _decode_session(request.cookies.get(SESSION_COOKIE))


def _ctx(request: Request, **extra: Any) -> dict:
    return {"request": request, "user": _user(request), "labs": LABS, **extra}


def _lab(slug: str) -> dict | None:
    return next((lab for lab in LABS if lab["slug"] == slug), None)


@app.get("/")
def home():
    return RedirectResponse("/labs", status_code=302)


@app.get("/labs", response_class=HTMLResponse)
def labs_index(request: Request):
    return templates.TemplateResponse("labs.html", _ctx(request, title="Labs"))


@app.get("/labs/{slug}", response_class=HTMLResponse)
def lab_detail(request: Request, slug: str):
    lab = _lab(slug)
    if not lab:
        return HTMLResponse("Lab not found", status_code=404)
    result = None
    if slug == "secrets":
        result = {
            "ok": True,
            "env": {
                "JWZ_DEMO_AWS_ACCESS_KEY_ID": os.getenv("JWZ_DEMO_AWS_ACCESS_KEY_ID", ""),
                "JWZ_DEMO_AWS_SECRET_ACCESS_KEY": os.getenv(
                    "JWZ_DEMO_AWS_SECRET_ACCESS_KEY", ""
                ),
                "JWZ_DEMO_DB_PASSWORD": os.getenv("JWZ_DEMO_DB_PASSWORD", ""),
            },
            "note": "Synthetic demo credentials only — never real cloud keys.",
        }
    return templates.TemplateResponse(
        "lab.html",
        _ctx(request, title=lab["title"], lab=lab, result=result),
    )


@app.get("/login", response_class=HTMLResponse)
def login_page(request: Request):
    return templates.TemplateResponse(
        "login.html", _ctx(request, title="Login", error=None)
    )


@app.post("/login", response_class=HTMLResponse)
def login_submit(
    request: Request,
    email: str = Form(...),
    password: str = Form(...),
):
    # Intentional SQLi — do not "fix"
    query = (
        f"SELECT email, name, role FROM users "
        f"WHERE email = '{email}' AND password = '{password}' LIMIT 1"
    )
    conn = sqlite3.connect(DB_PATH)
    try:
        row = conn.execute(query).fetchone()
    finally:
        conn.close()

    if not row:
        return templates.TemplateResponse(
            "login.html",
            _ctx(request, title="Login", error="Invalid credentials", query=query),
            status_code=401,
        )

    user = {"email": row[0], "name": row[1], "role": row[2]}
    resp = RedirectResponse("/labs", status_code=302)
    resp.set_cookie(SESSION_COOKIE, _encode_session(user), httponly=False)
    return resp


@app.post("/labs/path-traversal", response_class=HTMLResponse)
def path_traversal(request: Request, name: str = Form("welcome.txt")):
    lab = _lab("path-traversal")
    public = SECRETS / "public"
    # Intentional traversal via join
    full = os.path.join(str(public), name)
    try:
        content = Path(full).read_text(encoding="utf-8", errors="replace")
        result = {"ok": True, "path": full, "content": content}
    except Exception as exc:  # noqa: BLE001
        result = {"ok": False, "path": full, "error": str(exc)}
    return templates.TemplateResponse(
        "lab.html", _ctx(request, title=lab["title"], lab=lab, result=result)
    )


@app.post("/labs/cmd-injection", response_class=HTMLResponse)
def cmd_injection(request: Request, host: str = Form("127.0.0.1")):
    lab = _lab("cmd-injection")
    # Intentional command injection
    cmd = f"ping -c 1 {host}"
    try:
        proc = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=8
        )
        result = {
            "ok": True,
            "command": cmd,
            "returncode": proc.returncode,
            "stdout": (proc.stdout or "").strip(),
            "stderr": (proc.stderr or "").strip(),
        }
    except Exception as exc:  # noqa: BLE001
        result = {"ok": False, "command": cmd, "error": str(exc)}
    return templates.TemplateResponse(
        "lab.html", _ctx(request, title=lab["title"], lab=lab, result=result)
    )


@app.post("/labs/yaml-deser", response_class=HTMLResponse)
def yaml_deser(request: Request, payload: str = Form("name: rider\nboard: hyperlite")):
    lab = _lab("yaml-deser")
    try:
        loaded = yaml.load(payload)  # noqa: S506 — intentional unsafe_load surface
        marker = Path("/tmp/jwz-yaml-marker.txt")
        marker.write_text(f"yaml-loaded={loaded!r}\n", encoding="utf-8")
        result = {
            "ok": True,
            "parsed": repr(loaded),
            "pyyaml": getattr(yaml, "__version__", "unknown"),
            "marker": str(marker),
        }
    except Exception as exc:  # noqa: BLE001
        result = {"ok": False, "error": str(exc)}
    return templates.TemplateResponse(
        "lab.html", _ctx(request, title=lab["title"], lab=lab, result=result)
    )


@app.get("/healthz")
def healthz():
    return {"ok": True, "service": "jays-wake-zone"}
