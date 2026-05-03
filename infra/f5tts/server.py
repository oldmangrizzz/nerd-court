"""Nerd Court F5-TTS service (GPU).

Implements the blueprint contract:
- F5-TTS zero-shot inference: any registered voice_id can synthesize any text.
- Voices are provisioned at runtime via POST /v1/voices/register {voice_id,
  youtube_url, clip_start_sec, clip_end_sec, ref_text, display_name}. The
  server delegates the YouTube/IA/SoundCloud → 24 kHz mono WAV materialization
  to the off-GCP yt-clipper microservice (Hostinger), because YouTube hard-
  blocks GCP egress IP ranges. F5-TTS-on-GPU stays on Cloud Run.
- Unlimited voice count. NO hardcoded staff registry.

Auth: shared-secret X-API-Key header (env NERDCOURT_API_KEY).
"""
from __future__ import annotations

import json
import os
import threading
import urllib.error
import urllib.request
from pathlib import Path
from tempfile import NamedTemporaryFile
from typing import Optional

from fastapi import FastAPI, Header, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel, Field

API_KEY = os.environ.get("NERDCOURT_API_KEY", "")
YT_CLIPPER_URL = os.environ.get("YT_CLIPPER_URL", "https://yt.grizzlymedicine.icu")
YT_CLIPPER_KEY = os.environ.get("YT_CLIPPER_KEY", API_KEY)
REF_DIR = Path(os.environ.get("NC_REF_DIR", "/tmp/nc_refs"))
REF_DIR.mkdir(parents=True, exist_ok=True)

# Lazy-loaded F5-TTS instance + lock — model is ~1.5 GB, load once.
_f5_lock = threading.Lock()
_f5_infer_lock = threading.Lock()
_f5_instance = None  # type: ignore[var-annotated]
_voice_meta: dict[str, dict] = {}
_meta_lock = threading.Lock()


def require_api_key(x_api_key: Optional[str]) -> None:
    if not API_KEY:
        return
    if not x_api_key or x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="invalid api key")


def get_f5tts():
    global _f5_instance
    if _f5_instance is None:
        with _f5_lock:
            if _f5_instance is None:
                from f5_tts.api import F5TTS
                _f5_instance = F5TTS(model="F5TTS_v1_Base")
    return _f5_instance


def _materialize_ref_clip(
    source: str, start_sec: float, end_sec: float, dst_path: Path
) -> None:
    """Call yt-clipper microservice to fetch+trim the reference clip."""
    body = json.dumps({
        "source": source, "start_sec": start_sec, "end_sec": end_sec,
    }).encode()
    req = urllib.request.Request(
        f"{YT_CLIPPER_URL}/v1/clip",
        data=body,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "X-API-Key": YT_CLIPPER_KEY,
            "User-Agent": "NerdCourt-F5TTS/2.0",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=240) as resp:
            audio = resp.read()
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")[:400]
        raise HTTPException(status_code=502, detail=f"yt-clipper {exc.code}: {body}")
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"yt-clipper request failed: {exc}")
    if not audio.startswith(b"RIFF"):
        raise HTTPException(status_code=502, detail="yt-clipper returned non-WAV payload")
    dst_path.write_bytes(audio)


def _register_voice(voice_id: str, youtube_url: str, clip_start_sec: float,
                    clip_end_sec: float, ref_text: str, display_name: str = "") -> dict:
    ref_path = REF_DIR / f"{voice_id}.ref.wav"
    _materialize_ref_clip(youtube_url, clip_start_sec, clip_end_sec, ref_path)
    meta = {
        "voice_id": voice_id,
        "display_name": display_name or voice_id,
        "youtube_url": youtube_url,
        "clip_start_sec": clip_start_sec,
        "clip_end_sec": clip_end_sec,
        "ref_text": ref_text,
        "ref_path": str(ref_path),
    }
    with _meta_lock:
        _voice_meta[voice_id] = meta
    return meta


# ---------------------------------------------------------------------------
# FastAPI surface
# ---------------------------------------------------------------------------

class RegisterRequest(BaseModel):
    voice_id: str
    youtube_url: str  # accepts URL or ytsearch1:/iasearch5:/scsearch1: directive
    clip_start_sec: float = 0.0
    clip_end_sec: float = 5.0
    ref_text: str = ""
    display_name: str = ""


class SynthesizeRequest(BaseModel):
    voice_id: str
    text: str
    nfe_step: int = Field(default=32, ge=8, le=64)
    speed: float = Field(default=1.0, gt=0.3, lt=2.5)


app = FastAPI(title="Nerd Court F5-TTS", version="2.1.0")


@app.get("/")
def root(x_api_key: Optional[str] = Header(default=None, alias="X-API-Key")) -> dict:
    require_api_key(x_api_key)
    with _meta_lock:
        return {
            "service": "nerd-court-f5tts",
            "model": "F5TTS_v1_Base",
            "voices": [
                {"voice_id": v["voice_id"], "display_name": v["display_name"]}
                for v in _voice_meta.values()
            ],
        }


@app.get("/healthz")
def healthz() -> dict:
    with _meta_lock:
        return {"status": "ok", "voice_count": len(_voice_meta)}


@app.post("/v1/voices/register")
def register_voice(
    req: RegisterRequest,
    x_api_key: Optional[str] = Header(default=None, alias="X-API-Key"),
) -> dict:
    require_api_key(x_api_key)
    if not req.voice_id.replace("_", "").replace("-", "").isalnum():
        raise HTTPException(status_code=400, detail="voice_id must be alphanumeric/underscore/dash")
    meta = _register_voice(
        voice_id=req.voice_id,
        youtube_url=req.youtube_url,
        clip_start_sec=req.clip_start_sec,
        clip_end_sec=req.clip_end_sec,
        ref_text=req.ref_text,
        display_name=req.display_name,
    )
    return {"status": "registered", "voice_id": meta["voice_id"]}


@app.post("/v1/synthesize")
def synthesize(
    req: SynthesizeRequest,
    x_api_key: Optional[str] = Header(default=None, alias="X-API-Key"),
) -> Response:
    require_api_key(x_api_key)
    text = req.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="text must be non-empty")

    with _meta_lock:
        meta = _voice_meta.get(req.voice_id)
    if meta is None:
        raise HTTPException(
            status_code=404,
            detail=f"voice_id '{req.voice_id}' not registered — POST /v1/voices/register first",
        )

    f5 = get_f5tts()
    with NamedTemporaryFile(suffix=".wav", delete=False) as out:
        out_path = Path(out.name)
    try:
        with _f5_infer_lock:
            f5.infer(
                ref_file=meta["ref_path"],
                ref_text=meta.get("ref_text", ""),
                gen_text=text,
                nfe_step=req.nfe_step,
                speed=req.speed,
                file_wave=str(out_path),
                seed=None,
            )
        audio_bytes = out_path.read_bytes()
    finally:
        out_path.unlink(missing_ok=True)

    return Response(
        content=audio_bytes,
        media_type="audio/wav",
        headers={
            "X-Voice-Id": req.voice_id,
            "X-Model": "F5TTS_v1_Base",
            "Content-Length": str(len(audio_bytes)),
        },
    )
