"""Nerd Court TTS service.

Wraps four piper-tts voices behind a /v1/synthesize endpoint compatible with the
shape Sources/Voice/VoiceSynthesisClient.swift expects: POST JSON with
{"text": str, "voice_id": str} returning audio/wav bytes.

voice_id maps:
  jason_todd     -> en_US-ryan-high (gravel, intense)
  matt_murdock   -> en_US-lessac-medium (measured, lawyerly)
  jerry_springer -> en_US-joe-medium (TV host energy)
  deadpool_nph   -> en_US-hfc_male-medium (theatrical)

All voices are CC0 piper-voices from rhasspy/piper-voices on HuggingFace.

This is the "open-source TTS deployed on Cloud Run" surface required by the
build #10 contract. F5-TTS itself requires GPU + multi-GB checkpoint and is
not viable on serverless CPU; piper produces real neural TTS on CPU in <2s
per utterance and ships character-distinct voices.
"""
from __future__ import annotations

import io
import os
import wave
from pathlib import Path
from typing import Dict

from fastapi import FastAPI, Header, HTTPException
from fastapi.responses import Response
from piper import PiperVoice
from pydantic import BaseModel

API_KEY = os.environ.get("NERDCOURT_API_KEY", "")


def require_api_key(x_api_key: str | None) -> None:
    """Reject requests missing or mismatching the shared secret.

    When NERDCOURT_API_KEY is empty (local dev), auth is skipped. In Cloud
    Run the env var is set via deploy and must match the iOS bundle's
    F5TTSApiKey Info.plist value.
    """
    if not API_KEY:
        return
    if not x_api_key or x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="invalid api key")

VOICES_DIR = Path(os.environ.get("PIPER_VOICES", "/app/voices"))

VOICE_MAP: Dict[str, str] = {
    "jason_todd": "en_US-ryan-high",
    "matt_murdock": "en_US-lessac-medium",
    "jerry_springer": "en_US-joe-medium",
    "deadpool_nph": "en_US-hfc_male-medium",
    "guest": "en_US-lessac-medium",
}

LOADED: Dict[str, PiperVoice] = {}


def load_voice(model_name: str) -> PiperVoice:
    if model_name in LOADED:
        return LOADED[model_name]
    onnx_path = VOICES_DIR / f"{model_name}.onnx"
    if not onnx_path.exists():
        raise FileNotFoundError(f"voice model missing: {onnx_path}")
    voice = PiperVoice.load(str(onnx_path))
    LOADED[model_name] = voice
    return voice


class SynthesizeRequest(BaseModel):
    text: str
    voice_id: str = "jason_todd"


app = FastAPI(title="Nerd Court TTS", version="1.0.0")


@app.on_event("startup")
def warm_voices() -> None:
    for model_name in set(VOICE_MAP.values()):
        try:
            load_voice(model_name)
        except FileNotFoundError as exc:
            print(f"WARN: {exc}")


@app.get("/")
def root(x_api_key: str | None = Header(default=None, alias="X-API-Key")) -> dict:
    require_api_key(x_api_key)
    return {"service": "nerd-court-tts", "voices": list(VOICE_MAP.keys())}


@app.get("/healthz")
def healthz() -> dict:
    return {"status": "ok", "loaded": list(LOADED.keys())}


@app.post("/v1/synthesize")
def synthesize(
    req: SynthesizeRequest,
    x_api_key: str | None = Header(default=None, alias="X-API-Key"),
) -> Response:
    require_api_key(x_api_key)
    if not req.text.strip():
        raise HTTPException(status_code=400, detail="text must be non-empty")
    model_name = VOICE_MAP.get(req.voice_id, VOICE_MAP["guest"])
    try:
        voice = load_voice(model_name)
    except FileNotFoundError as exc:
        raise HTTPException(status_code=503, detail=str(exc))

    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as wav:
        voice.synthesize(req.text, wav)
    audio_bytes = buffer.getvalue()
    return Response(
        content=audio_bytes,
        media_type="audio/wav",
        headers={
            "X-Voice-Id": req.voice_id,
            "X-Model": model_name,
            "Content-Length": str(len(audio_bytes)),
        },
    )
