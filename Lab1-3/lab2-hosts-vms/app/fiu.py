"""Function-in-Use sinks — operational CVEs that Upwind can observe.

Each sink:
  * is called on a heartbeat (FiU without a click)
  * is exposed on an HTTP path (operational / exploitable)

| CVE              | Package / lib     | Function(s) in use                          |
|------------------|-------------------|---------------------------------------------|
| CVE-2023-50447   | pillow==10.0.1    | PIL.ImageMath.eval                          |
| CVE-2026-112403  | pillow==10.0.1    | ImagingJpegDecode via Image.thumbnail/draft |
| CVE-2026-112900  | pillow==10.0.1+gs | EpsImagePlugin → Ghostscript                |
| CVE-2026-111497  | brotli==1.1.0     | DecodeBlockTypeAndLength (brotli.decompress)|
| CVE-2020-14343   | pyyaml==5.3.1     | yaml.load(Loader=Loader)                    |
| CVE-2007-4559    | stdlib tarfile    | TarFile.extract / extractall                |

"""
from __future__ import annotations

import base64
import importlib.metadata
import io
import tarfile
import threading
import time
from pathlib import Path
from typing import Any

INTERVAL_SECONDS = 60
WORK = Path("/tmp/jwz-fiu")

PILLOW_MARKER = WORK / "pillow.txt"
BROTLI_MARKER = WORK / "brotli.txt"
YAML_MARKER = WORK / "yaml.txt"
TAR_MARKER = WORK / "tarfile.txt"
JPEG_MARKER = WORK / "jpeg.txt"
EPS_MARKER = WORK / "eps.txt"

PILLOW_HEARTBEAT_EXPR = "convert(RGB, 'L')"
YAML_HEARTBEAT = "ride: warm-up\nprice: 42\n"
BROTLI_HEARTBEAT_PLAIN = b"jays-wake-zone-fiu-heartbeat"

_lock = threading.Lock()
_stats: dict[str, dict[str, Any]] = {
    k: {"heartbeat_calls": 0, "http_calls": 0, "last_at": None}
    for k in ("imagemath", "jpeg", "eps", "brotli", "yaml", "tarfile")
}


def _pkg_ver(name: str) -> str:
    try:
        return importlib.metadata.version(name)
    except Exception:
        return "unknown"


def _now() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def _bump(key: str, *, source: str) -> dict[str, Any]:
    with _lock:
        s = _stats[key]
        s["last_at"] = _now()
        s["heartbeat_calls" if source == "heartbeat" else "http_calls"] += 1
        return dict(s)


def _tiny_png_bytes() -> bytes:
    """1x1 PNG — enough to open/thumbnail without a fixture file."""
    from PIL import Image

    buf = io.BytesIO()
    Image.new("RGB", (64, 64), color=(30, 160, 180)).save(buf, format="JPEG")
    return buf.getvalue()


# ----- CVE-2023-50447 — Pillow ImageMath.eval --------------------------------

def call_imagemath_eval(expr: str, *, source: str) -> dict[str, Any]:
    from PIL import Image, ImageMath

    env = {"RGB": Image.new("RGB", (8, 8), color=(32, 160, 180))}
    err = None
    try:
        ImageMath.eval(expr, **env)  # noqa: S307 — intentional
    except Exception as exc:  # noqa: BLE001
        err = str(exc)
    snap = _bump("imagemath", source=source)
    ver = _pkg_ver("pillow")
    PILLOW_MARKER.write_text(
        f"function=PIL.ImageMath.eval\ncve=CVE-2023-50447\nsource={source}\n"
        f"pillow={ver}\nexpr={expr}\nat={_now()}\n",
        encoding="utf-8",
    )
    return {
        "ok": True,
        "cve": "CVE-2023-50447",
        "function_in_use": "PIL.ImageMath.eval",
        "package": f"pillow=={ver}",
        "source": source,
        "expr": expr,
        "eval_error": err,
        "marker": str(PILLOW_MARKER),
        "stats": snap,
    }


# ----- CVE-2026-112403 — Pillow JPEG draft/thumbnail path --------------------

def call_jpeg_thumbnail(image_bytes: bytes, *, source: str) -> dict[str, Any]:
    """Image.open → thumbnail/draft — hits ImagingJpegDecode (CVE-2026-112403 class)."""
    from PIL import Image

    err = None
    size = None
    try:
        img = Image.open(io.BytesIO(image_bytes))
        img.thumbnail((32, 32))  # calls draft() internally
        size = img.size
    except Exception as exc:  # noqa: BLE001
        err = str(exc)
    snap = _bump("jpeg", source=source)
    ver = _pkg_ver("pillow")
    JPEG_MARKER.write_text(
        f"function=Image.thumbnail/draft → ImagingJpegDecode\n"
        f"cve=CVE-2026-112403\nsource={source}\npillow={ver}\nat={_now()}\n",
        encoding="utf-8",
    )
    return {
        "ok": err is None,
        "cve": "CVE-2026-112403",
        "function_in_use": "Image.thumbnail → ImagingJpegDecode",
        "package": f"pillow=={ver}",
        "source": source,
        "size": size,
        "error": err,
        "marker": str(JPEG_MARKER),
        "stats": snap,
    }


# ----- CVE-2026-112900 — Pillow EPS → Ghostscript ----------------------------

def call_eps_open(filename: str, *, source: str) -> dict[str, Any]:
    """Image.open on an .eps path — EpsImagePlugin shells to Ghostscript.

    CVE-2026-112900: attacker-controlled filename → Ghostscript arg injection.
    Heartbeat uses a benign absolute path; HTTP accepts a caller-chosen name.
    """
    from PIL import Image

    err = None
    try:
        Image.open(filename)
    except Exception as exc:  # noqa: BLE001
        err = str(exc)
    snap = _bump("eps", source=source)
    ver = _pkg_ver("pillow")
    EPS_MARKER.write_text(
        f"function=EpsImagePlugin.Ghostscript\ncve=CVE-2026-112900\n"
        f"source={source}\nfilename={filename}\npillow={ver}\nat={_now()}\n"
        f"error={err}\n",
        encoding="utf-8",
    )
    return {
        "ok": err is None,
        "cve": "CVE-2026-112900",
        "function_in_use": "EpsImagePlugin.Ghostscript",
        "package": f"pillow=={ver}",
        "source": source,
        "filename": filename,
        "error": err,
        "marker": str(EPS_MARKER),
        "stats": snap,
        "note": "Requires ghostscript on PATH. Filename is the injection surface.",
    }


def _ensure_benign_eps() -> Path:
    WORK.mkdir(parents=True, exist_ok=True)
    path = WORK / "benign.eps"
    if not path.exists():
        # Minimal EPS — enough for Ghostscript to be invoked
        path.write_text(
            "%!PS-Adobe-3.0 EPSF-3.0\n"
            "%%BoundingBox: 0 0 10 10\n"
            "newpath 0 0 moveto 10 10 lineto stroke\n"
            "showpage\n",
            encoding="utf-8",
        )
    return path


# ----- CVE-2026-111497 — Brotli HTTP2Shell -----------------------------------

def call_brotli_decompress(payload: bytes, *, source: str) -> dict[str, Any]:
    import brotli

    err = None
    plain: bytes | None = None
    try:
        plain = brotli.decompress(payload)
    except Exception as exc:  # noqa: BLE001
        err = str(exc)
    snap = _bump("brotli", source=source)
    ver = _pkg_ver("brotli")
    BROTLI_MARKER.write_text(
        f"function=brotli.decompress → DecodeBlockTypeAndLength\n"
        f"cve=CVE-2026-111497\nname=HTTP2Shell\nsource={source}\n"
        f"brotli={ver}\nbytes={len(payload)}\nat={_now()}\nerror={err}\n",
        encoding="utf-8",
    )
    return {
        "ok": err is None,
        "cve": "CVE-2026-111497",
        "name": "HTTP2Shell",
        "function_in_use": "DecodeBlockTypeAndLength (via brotli.decompress)",
        "package": f"brotli=={ver}",
        "source": source,
        "payload_bytes": len(payload),
        "plaintext": plain.decode("utf-8", errors="replace") if plain else None,
        "decode_error": err,
        "marker": str(BROTLI_MARKER),
        "stats": snap,
    }


def call_brotli_decompress_b64(payload_b64: str, *, source: str) -> dict[str, Any]:
    try:
        raw = base64.b64decode(payload_b64)
    except Exception as exc:  # noqa: BLE001
        return {"ok": False, "error": f"invalid base64: {exc}", "cve": "CVE-2026-111497"}
    return call_brotli_decompress(raw, source=source)


# ----- CVE-2020-14343 — PyYAML unsafe load -----------------------------------

def call_yaml_load(manifest: str, *, source: str) -> dict[str, Any]:
    import yaml

    err = None
    parsed: Any = None
    try:
        parsed = yaml.load(manifest, Loader=yaml.Loader)  # noqa: S506
    except Exception as exc:  # noqa: BLE001
        err = str(exc)
    snap = _bump("yaml", source=source)
    ver = _pkg_ver("pyyaml")
    YAML_MARKER.write_text(
        f"function=yaml.load\ncve=CVE-2020-14343\nsource={source}\n"
        f"pyyaml={ver}\nat={_now()}\nparsed={parsed!r}\nerror={err}\n",
        encoding="utf-8",
    )
    return {
        "ok": err is None,
        "cve": "CVE-2020-14343",
        "function_in_use": "yaml.load (Loader=yaml.Loader)",
        "package": f"pyyaml=={ver}",
        "source": source,
        "parsed": repr(parsed) if parsed is not None else None,
        "load_error": err,
        "marker": str(YAML_MARKER),
        "stats": snap,
    }


# ----- CVE-2007-4559 — tarfile path traversal --------------------------------

def call_tar_extract(archive_bytes: bytes, dest: Path, *, source: str) -> dict[str, Any]:
    """TarFile.extractall without a filter — CVE-2007-4559 class."""
    err = None
    members: list[str] = []
    dest.mkdir(parents=True, exist_ok=True)
    try:
        with tarfile.open(fileobj=io.BytesIO(archive_bytes), mode="r:*") as tf:
            members = [m.name for m in tf.getmembers()]
            # Intentional: no filter= — traversal-prone default on 3.11/3.12/3.13
            tf.extractall(path=dest)  # noqa: S202
    except Exception as exc:  # noqa: BLE001
        err = str(exc)
    snap = _bump("tarfile", source=source)
    TAR_MARKER.write_text(
        f"function=tarfile.TarFile.extractall\ncve=CVE-2007-4559\n"
        f"source={source}\ndest={dest}\nmembers={members}\nat={_now()}\nerror={err}\n",
        encoding="utf-8",
    )
    return {
        "ok": err is None,
        "cve": "CVE-2007-4559",
        "function_in_use": "tarfile.TarFile.extractall",
        "package": "stdlib tarfile",
        "source": source,
        "dest": str(dest),
        "members": members,
        "error": err,
        "marker": str(TAR_MARKER),
        "stats": snap,
        "note": "On Python <3.14 default filter is unsafe (PEP 706).",
    }


def _benign_tar_bytes() -> bytes:
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w") as tf:
        data = b"wake-zone-ok\n"
        info = tarfile.TarInfo(name="readme.txt")
        info.size = len(data)
        tf.addfile(info, io.BytesIO(data))
    return buf.getvalue()


def start_heartbeat(interval_sec: float = INTERVAL_SECONDS) -> None:
    """Keep every vulnerable function hot for Function-in-Use detection."""
    import brotli

    WORK.mkdir(parents=True, exist_ok=True)
    warm_br = brotli.compress(BROTLI_HEARTBEAT_PLAIN)
    warm_jpeg = _tiny_png_bytes()
    warm_tar = _benign_tar_bytes()
    eps = _ensure_benign_eps()

    def _loop() -> None:
        time.sleep(3)
        while True:
            for fn in (
                lambda: call_imagemath_eval(PILLOW_HEARTBEAT_EXPR, source="heartbeat"),
                lambda: call_jpeg_thumbnail(warm_jpeg, source="heartbeat"),
                lambda: call_eps_open(str(eps), source="heartbeat"),
                lambda: call_brotli_decompress(warm_br, source="heartbeat"),
                lambda: call_yaml_load(YAML_HEARTBEAT, source="heartbeat"),
                lambda: call_tar_extract(warm_tar, WORK / "tar-out", source="heartbeat"),
            ):
                try:
                    fn()
                except Exception:  # noqa: BLE001
                    pass
            time.sleep(interval_sec)

    threading.Thread(target=_loop, name="jwz-fiu-heartbeat", daemon=True).start()


def stats() -> dict[str, Any]:
    with _lock:
        snaps = {k: dict(v) for k, v in _stats.items()}
    try:
        import brotli

        sample_b64 = base64.b64encode(brotli.compress(b"wake-zone-ok")).decode()
    except Exception:
        sample_b64 = ""
    return {
        "heartbeat_interval_sec": INTERVAL_SECONDS,
        "cves": [
            {
                "cve": "CVE-2023-50447",
                "package": f"pillow=={_pkg_ver('pillow')}",
                "function_in_use": "PIL.ImageMath.eval",
                "exploit": "POST /api/board/preview",
                "stats": snaps["imagemath"],
            },
            {
                "cve": "CVE-2026-112403",
                "package": f"pillow=={_pkg_ver('pillow')}",
                "function_in_use": "Image.thumbnail → ImagingJpegDecode",
                "exploit": "POST /api/image/thumbnail",
                "stats": snaps["jpeg"],
            },
            {
                "cve": "CVE-2026-112900",
                "package": f"pillow=={_pkg_ver('pillow')} + ghostscript",
                "function_in_use": "EpsImagePlugin.Ghostscript",
                "exploit": "POST /api/image/eps",
                "stats": snaps["eps"],
            },
            {
                "cve": "CVE-2026-111497",
                "name": "HTTP2Shell",
                "package": f"brotli=={_pkg_ver('brotli')}",
                "function_in_use": "DecodeBlockTypeAndLength",
                "exploit": "POST /api/decode/brotli",
                "benign_sample_b64": sample_b64,
                "stats": snaps["brotli"],
            },
            {
                "cve": "CVE-2020-14343",
                "package": f"pyyaml=={_pkg_ver('pyyaml')}",
                "function_in_use": "yaml.load (Loader=Loader)",
                "exploit": "POST /api/checkout",
                "stats": snaps["yaml"],
            },
            {
                "cve": "CVE-2007-4559",
                "package": "stdlib tarfile",
                "function_in_use": "TarFile.extractall",
                "exploit": "POST /api/archive/extract",
                "stats": snaps["tarfile"],
            },
        ],
    }
