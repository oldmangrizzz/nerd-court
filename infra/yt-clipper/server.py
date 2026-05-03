"""Nerd Court yt-clipper microservice (runs on Hostinger / Charlie).

Materializes a 24 kHz mono WAV reference clip from a YouTube/Internet
Archive/SoundCloud source. Lives off-GCP because YouTube hard-blocks GCP
egress IPs as bots; Hostinger's residential-class IPs do not get bot-blocked.

Auth: shared-secret X-API-Key (env NERDCOURT_API_KEY).
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, Header, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel, Field

API_KEY = os.environ.get("NERDCOURT_API_KEY", "")
YT_API_KEY = os.environ.get("YT_DATA_API_KEY", "")


def _require(x_api_key: Optional[str]) -> None:
    if not API_KEY:
        return
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="invalid api key")


def _yt_api_resolve(query: str) -> Optional[str]:
    if not YT_API_KEY:
        return None
    params = urllib.parse.urlencode({
        "part": "snippet", "type": "video", "maxResults": "1",
        "videoEmbeddable": "true", "q": query, "key": YT_API_KEY,
    })
    req = urllib.request.Request(
        f"https://www.googleapis.com/youtube/v3/search?{params}",
        headers={"User-Agent": "NerdCourt/1.0"},
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read())
    except Exception as exc:
        print(f"[yt-api] {exc}")
        return None
    items = data.get("items") or []
    if not items:
        return None
    vid = items[0].get("id", {}).get("videoId")
    return f"https://www.youtube.com/watch?v={vid}" if vid else None


def _download(source: str, out_dir: Path) -> Path:
    """Download `source` (URL or ytsearch1:/iasearch5:/scsearch1: directive)
    to a single audio file in `out_dir`.
    """
    is_search = source.startswith(("ytsearch", "scsearch", "iasearch"))
    raw_query = source.split(":", 1)[1] if is_search else source

    base = ["yt-dlp", "-f", "bestaudio/best", "-x", "--audio-format", "wav",
            "--no-playlist", "-o", str(out_dir / "src.%(ext)s")]
    yt_args = ["--extractor-args", "youtube:player_client=android,ios,web"]

    attempts: list[list[str]] = []
    if is_search and source.startswith("ytsearch"):
        resolved = _yt_api_resolve(raw_query)
        if resolved:
            attempts.append(base + yt_args + [resolved])
        attempts.append(base + [f"iasearch5:{raw_query}"])
        attempts.append(base + [f"scsearch1:{raw_query}"])
        attempts.append(base + yt_args + [f"ytsearch1:{raw_query}"])
    elif is_search:
        attempts.append(base + [source])
    else:
        attempts.append(base + yt_args + [source])

    last_err = "no attempts"
    for cmd in attempts:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
        files = list(out_dir.glob("src.*"))
        if proc.returncode == 0 and files:
            return files[0]
        last_err = (proc.stderr or "")[-500:]
        for f in files:
            f.unlink(missing_ok=True)
    raise HTTPException(status_code=502, detail=f"yt-dlp exhausted backends: {last_err}")


def _trim(src: Path, dst: Path, start: float, end: float) -> None:
    duration = max(1.0, end - start)
    proc = subprocess.run(
        ["ffmpeg", "-y", "-ss", f"{start:.3f}", "-t", f"{duration:.3f}",
         "-i", str(src), "-ac", "1", "-ar", "24000", str(dst)],
        capture_output=True, text=True, timeout=60,
    )
    if proc.returncode != 0:
        raise HTTPException(status_code=502, detail=f"ffmpeg trim failed: {proc.stderr[-400:]}")


class ClipRequest(BaseModel):
    source: str = Field(..., description="URL or ytsearch1:/iasearch5:/scsearch1: directive")
    start_sec: float = 0.0
    end_sec: float = 5.0


app = FastAPI(title="Nerd Court yt-clipper", version="1.0.0")


@app.get("/healthz")
def healthz() -> dict:
    return {"status": "ok"}


@app.post("/v1/clip")
def clip(req: ClipRequest, x_api_key: Optional[str] = Header(default=None, alias="X-API-Key")) -> Response:
    _require(x_api_key)
    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)
        src = _download(req.source, tmp_dir)
        out = tmp_dir / "clip.wav"
        _trim(src, out, req.start_sec, req.end_sec)
        audio = out.read_bytes()
    return Response(
        content=audio, media_type="audio/wav",
        headers={"Content-Length": str(len(audio)), "X-Source": req.source[:120]},
    )
