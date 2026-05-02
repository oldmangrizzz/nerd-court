"""Production regression tests for the deployed Nerd Court TTS service.

Run:
    TTS_URL=https://nerd-court-tts-219679773601.us-central1.run.app \
    TTS_BEARER="$(gcloud auth print-identity-token)" \
    pytest scripts/regression/test_tts_service.py -v

These tests hit the live Cloud Run deployment. Failure means production is broken.
"""
from __future__ import annotations

import concurrent.futures
import io
import os
import time
import wave
from typing import Iterable

import pytest
import requests

TTS_URL = os.environ.get("TTS_URL", "https://nerd-court-tts-219679773601.us-central1.run.app")
TTS_BEARER = os.environ.get("TTS_BEARER", "")
LATENCY_BUDGET_S = float(os.environ.get("TTS_LATENCY_BUDGET_S", "15.0"))

REQUIRED_VOICES = ("jason_todd", "matt_murdock", "jerry_springer", "deadpool_nph")

SCRIPTED_LINES: dict[str, str] = {
    "jason_todd": "Court is in session. I literally died, you do not see me stealing names.",
    "matt_murdock": "Your honor, the defendant cannot be convicted on canon hearsay.",
    "jerry_springer": "Today on Jerry Springer: canon violators. Roll the tape, my final thought is coming.",
    "deadpool_nph": "Hi, I am Neil Patrick Harris filling in as your bailiff. Buckle up, kids.",
}


def _headers() -> dict[str, str]:
    h = {"Content-Type": "application/json"}
    if TTS_BEARER:
        h["Authorization"] = f"Bearer {TTS_BEARER}"
    return h


def _wav_duration(audio: bytes) -> float:
    with wave.open(io.BytesIO(audio), "rb") as wav:
        frames = wav.getnframes()
        rate = wav.getframerate()
        return frames / float(rate) if rate else 0.0


def _post_synthesize(text: str, voice_id: str, timeout: float = 30.0) -> requests.Response:
    return requests.post(
        f"{TTS_URL}/v1/synthesize",
        headers=_headers(),
        json={"text": text, "voice_id": voice_id},
        timeout=timeout,
    )


@pytest.mark.parametrize("voice_id", REQUIRED_VOICES)
def test_each_voice_returns_valid_wav(voice_id: str) -> None:
    text = SCRIPTED_LINES[voice_id]
    resp = _post_synthesize(text, voice_id)
    assert resp.status_code == 200, f"{voice_id} returned HTTP {resp.status_code}: {resp.text[:200]}"
    assert resp.headers["Content-Type"].startswith("audio/wav"), resp.headers
    assert resp.headers.get("X-Voice-Id") == voice_id
    audio = resp.content
    assert len(audio) > 8000, f"{voice_id} produced suspiciously small wav: {len(audio)} bytes"
    duration = _wav_duration(audio)
    assert duration >= 1.0, f"{voice_id} duration {duration:.2f}s is below 1s for a full sentence"


def test_voices_are_audibly_distinct() -> None:
    """Different voice_ids must use different piper models; verify via X-Model header."""
    seen: set[str] = set()
    for voice_id in REQUIRED_VOICES:
        resp = _post_synthesize(SCRIPTED_LINES[voice_id], voice_id)
        assert resp.status_code == 200
        model = resp.headers.get("X-Model", "")
        assert model, f"{voice_id} missing X-Model header"
        seen.add(model)
    assert len(seen) == len(REQUIRED_VOICES), f"Voice models collapsed to {seen}; not character-distinct"


def test_unknown_voice_falls_back_to_guest() -> None:
    resp = _post_synthesize("Witness for the prosecution.", "spider_man")
    assert resp.status_code == 200
    assert resp.headers.get("X-Voice-Id") == "spider_man"


def test_empty_text_returns_400() -> None:
    resp = _post_synthesize("", "jason_todd")
    assert resp.status_code == 400


def test_whitespace_only_returns_400() -> None:
    resp = _post_synthesize("   \n\t  ", "jason_todd")
    assert resp.status_code == 400


def test_long_text_synthesizes_within_latency_budget() -> None:
    long_text = (
        "Ladies and gentlemen of Nerd Court. Today's grievance is filed by Jason Peter Todd, "
        "the Red Hood, against DC editorial for canon violations spanning three reboots, two "
        "Crisis events, and one frankly insulting retcon. The plaintiff died. The plaintiff "
        "came back. The plaintiff is once again here to demand accountability."
    )
    start = time.monotonic()
    resp = _post_synthesize(long_text, "jason_todd", timeout=LATENCY_BUDGET_S + 5)
    elapsed = time.monotonic() - start
    assert resp.status_code == 200
    assert elapsed <= LATENCY_BUDGET_S, f"long-text synth took {elapsed:.2f}s > {LATENCY_BUDGET_S}s budget"
    assert _wav_duration(resp.content) >= 8.0


def test_concurrent_requests_do_not_collide() -> None:
    """5 parallel requests must all return 200 with valid wavs."""

    def _one(voice_id: str) -> tuple[int, int, str]:
        resp = _post_synthesize(SCRIPTED_LINES[voice_id], voice_id, timeout=30)
        return resp.status_code, len(resp.content), resp.headers.get("X-Model", "")

    voice_cycle: Iterable[str] = list(REQUIRED_VOICES) + ["jason_todd"]
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
        results = list(pool.map(_one, voice_cycle))
    for status, size, model in results:
        assert status == 200
        assert size > 8000
        assert model


def test_root_advertises_voice_catalog() -> None:
    resp = requests.get(f"{TTS_URL}/", headers=_headers(), timeout=10)
    assert resp.status_code == 200
    body = resp.json()
    assert body["service"] == "nerd-court-tts"
    advertised = set(body["voices"])
    for voice in REQUIRED_VOICES:
        assert voice in advertised, f"root response missing {voice}"


def test_cold_start_first_response_under_budget() -> None:
    """Force a "first" hit by sleeping a moment between calls; cold start should be <30s."""
    start = time.monotonic()
    resp = _post_synthesize("Order in the court.", "matt_murdock", timeout=45)
    elapsed = time.monotonic() - start
    assert resp.status_code == 200
    assert elapsed <= 30.0, f"cold start latency {elapsed:.2f}s exceeds 30s budget"
