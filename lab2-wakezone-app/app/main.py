"""Jay's Wake Zone — SA onboarding DVWA-lite with multiple Function-in-Use CVEs.

See app/fiu.py for the CVE table and heartbeat.
"""
from __future__ import annotations

import base64
import json
import os
import sqlite3
import subprocess
from pathlib import Path
from typing import Any

import fiu
from fastapi import FastAPI, File, Form, Request, UploadFile
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel

APP_DIR = Path(__file__).parent
SECRETS = APP_DIR / "demo-secrets"
DB_PATH = Path("/tmp/jayswakezone.db")
SESSION_COOKIE = "jwz_session"

app = FastAPI(title="Jay's Wake Zone", version="0.4.0")
app.mount("/static", StaticFiles(directory=APP_DIR / "static"), name="static")
templates = Jinja2Templates(directory=str(APP_DIR / "templates"))

LABS = [
    {
        "slug": "fiu-pillow-imagemath",
        "ref": "CVE-2023-50447",
        "title": "Pillow ImageMath.eval",
        "blurb": "Eval RCE — heartbeat + POST /api/board/preview.",
    },
    {
        "slug": "fiu-pillow-jpeg",
        "ref": "CVE-2026-112403",
        "title": "Pillow JPEG thumbnail",
        "blurb": "ImagingJpegDecode via thumbnail/draft — POST /api/image/thumbnail.",
    },
    {
        "slug": "fiu-pillow-eps",
        "ref": "CVE-2026-112900",
        "title": "Pillow EPS → Ghostscript",
        "blurb": "Filename arg injection into gs — POST /api/image/eps.",
    },
    {
        "slug": "fiu-brotli",
        "ref": "CVE-2026-111497",
        "title": "Brotli HTTP2Shell",
        "blurb": "DecodeBlockTypeAndLength via brotli.decompress — POST /api/decode/brotli.",
    },
    {
        "slug": "fiu-yaml",
        "ref": "CVE-2020-14343",
        "title": "PyYAML unsafe load",
        "blurb": "yaml.load(Loader=Loader) — POST /api/checkout.",
    },
    {
        "slug": "fiu-tarfile",
        "ref": "CVE-2007-4559",
        "title": "tarfile extractall traversal",
        "blurb": "Stdlib TarFile.extractall without filter — POST /api/archive/extract.",
    },
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
        "slug": "secrets",
        "ref": "A07",
        "title": "Hardcoded secrets",
        "blurb": "Demo cloud keys and DB password shipped in the environment.",
    },
    {
        "slug": "webmin",
        "ref": "Mgmt",
        "title": "Exposed Webmin",
        "blurb": "Internet-facing Linux admin UI — login admin / password → host compromise.",
    },
]

FIU_SLUGS = {lab["slug"] for lab in LABS if lab["slug"].startswith("fiu-")}


def init_db() -> None:
    conn = sqlite3.connect(DB_PATH)
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY, email TEXT, password TEXT, name TEXT, role TEXT
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
    fiu.start_heartbeat()


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
        }
    elif slug in FIU_SLUGS:
        result = fiu.stats()
    return templates.TemplateResponse(
        "lab.html", _ctx(request, title=lab["title"], lab=lab, result=result)
    )


# ----- FiU exploit APIs ------------------------------------------------------


class PreviewRequest(BaseModel):
    design: str = "hyperlite"
    math_expr: str = "convert(RGB, 'L')"


@app.post("/api/board/preview")
def board_preview(req: PreviewRequest):
    out = fiu.call_imagemath_eval(req.math_expr, source="http")
    out["design"] = req.design
    return out


@app.post("/api/image/thumbnail")
async def image_thumbnail(file: UploadFile = File(...)):
    data = await file.read()
    return fiu.call_jpeg_thumbnail(data, source="http")


class EpsRequest(BaseModel):
    filename: str


@app.post("/api/image/eps")
def image_eps(req: EpsRequest):
    return fiu.call_eps_open(req.filename, source="http")


class BrotliRequest(BaseModel):
    payload_b64: str


@app.post("/api/decode/brotli")
def decode_brotli(req: BrotliRequest):
    return fiu.call_brotli_decompress_b64(req.payload_b64, source="http")


class CheckoutRequest(BaseModel):
    fulfillment_manifest: str = "items:\n  - board: hyperlite\n"


@app.post("/api/checkout")
def checkout(req: CheckoutRequest):
    return fiu.call_yaml_load(req.fulfillment_manifest, source="http")


@app.post("/api/archive/extract")
async def archive_extract(file: UploadFile = File(...)):
    data = await file.read()
    return fiu.call_tar_extract(data, Path("/tmp/jwz-fiu/http-extract"), source="http")


# ----- Classic AppSec --------------------------------------------------------


@app.get("/login", response_class=HTMLResponse)
def login_page(request: Request):
    return templates.TemplateResponse(
        "login.html", _ctx(request, title="Login", error=None)
    )


@app.post("/login", response_class=HTMLResponse)
def login_submit(
    request: Request, email: str = Form(...), password: str = Form(...)
):
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


@app.get("/healthz")
def healthz():
    return {"ok": True, "service": "jays-wake-zone", "function_in_use": fiu.stats()}
