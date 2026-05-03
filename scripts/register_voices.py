#!/usr/bin/env python3
"""Register the four character voices on the live F5-TTS Cloud Run service
and synthesize a smoke-test line for each.

NOTE: The session runtime forbids writing to /tmp, so script + outputs live
under the repo (scripts/, build/voicecheck/). Behavior is otherwise as spec'd.
"""
import json
import os
import sys
import time
import urllib.request
import urllib.error

BASE = "https://nerd-court-tts-219679773601.us-east4.run.app"
API_KEY = "RudbPuGZGArfE9iEgqvzV-5Pah0vPNAE3mYYefX3hgQ"
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "build", "voicecheck")
OUT_DIR = os.path.abspath(OUT_DIR)
os.makedirs(OUT_DIR, exist_ok=True)

TEST_LINE = "Court is in session. The plaintiff will state their case."

# Each entry: candidate registrations to try in order until one succeeds.
VOICES = {
    "jason_todd": [
        {
            # Jensen Ackles as Jason Todd / Red Hood in
            # "Batman: Under the Red Hood" (2010) — the only animated
            # source where Jason is voiced by an actor playing Jason.
            "display_name": "Jason Todd",
            "youtube_url": "ytsearch1:Jason Todd Red Hood Why on God's earth is he still alive Jensen Ackles",
            "clip_start_sec": 5.0,
            "clip_end_sec": 18.0,
            "ref_text": "",
        },
        {
            "display_name": "Jason Todd",
            "youtube_url": "ytsearch1:Under the Red Hood Jason confronts Batman Joker rooftop scene",
            "clip_start_sec": 20.0,
            "clip_end_sec": 33.0,
            "ref_text": "",
        },
        {
            "display_name": "Jason Todd",
            "youtube_url": "ytsearch1:Jensen Ackles Red Hood warehouse drug lords speech",
            "clip_start_sec": 8.0,
            "clip_end_sec": 22.0,
            "ref_text": "",
        },
    ],
    "matt_murdock": [
        {
            "display_name": "Matt Murdock (Charlie Cox courtroom)",
            "youtube_url": "ytsearch1:Charlie Cox Daredevil courtroom monologue Nelson Murdock",
            "clip_start_sec": 8.0,
            "clip_end_sec": 22.0,
            "ref_text": "",
        },
        {
            "display_name": "Matt Murdock (Daredevil closing argument)",
            "youtube_url": "ytsearch1:Matt Murdock closing argument Daredevil Netflix scene",
            "clip_start_sec": 5.0,
            "clip_end_sec": 19.0,
            "ref_text": "",
        },
        {
            "display_name": "Matt Murdock (Daredevil priest scene)",
            "youtube_url": "ytsearch1:Daredevil Charlie Cox church confession monologue",
            "clip_start_sec": 10.0,
            "clip_end_sec": 24.0,
            "ref_text": "",
        },
    ],
    "jerry_springer": [
        {
            "display_name": "Jerry Springer (Final Thought)",
            "youtube_url": "ytsearch1:Jerry Springer Final Thought full monologue",
            "clip_start_sec": 8.0,
            "clip_end_sec": 22.0,
            "ref_text": "",
        },
        {
            "display_name": "Jerry Springer (Final Thought)",
            "youtube_url": "ytsearch1:Jerry Springer final thoughts compilation closing",
            "clip_start_sec": 12.0,
            "clip_end_sec": 26.0,
            "ref_text": "",
        },
        {
            "display_name": "Jerry Springer (closing)",
            "youtube_url": "ytsearch1:Jerry Springer Show takes care of yourself and each other",
            "clip_start_sec": 5.0,
            "clip_end_sec": 18.0,
            "ref_text": "",
        },
    ],
    "deadpool_nph": [
        {
            "display_name": "Deadpool (NPH HIMYM narration)",
            "youtube_url": "ytsearch1:How I Met Your Mother Ted narration Bob Saget kids gather around",
            "clip_start_sec": 5.0,
            "clip_end_sec": 18.0,
            "ref_text": "",
        },
        {
            "display_name": "Deadpool (NPH Dr Horrible monologue)",
            "youtube_url": "ytsearch1:Dr Horrible Sing Along Blog Neil Patrick Harris video blog monologue spoken",
            "clip_start_sec": 8.0,
            "clip_end_sec": 22.0,
            "ref_text": "",
        },
        {
            "display_name": "Deadpool (NPH interview)",
            "youtube_url": "ytsearch1:Neil Patrick Harris monologue speech award acceptance spoken",
            "clip_start_sec": 5.0,
            "clip_end_sec": 19.0,
            "ref_text": "",
        },
    ],
}


def post_json(path, body, timeout):
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        BASE + path,
        data=data,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "X-API-Key": API_KEY,
        },
    )
    return urllib.request.urlopen(req, timeout=timeout)


def register(voice_id, candidate):
    body = {"voice_id": voice_id, **candidate}
    print(f"[register] {voice_id} <- {candidate['youtube_url']} [{candidate['clip_start_sec']}-{candidate['clip_end_sec']}]")
    t0 = time.time()
    try:
        resp = post_json("/v1/voices/register", body, timeout=300)
        payload = resp.read().decode("utf-8", errors="replace")
        print(f"  HTTP {resp.status} in {time.time()-t0:.1f}s :: {payload[:300]}")
        return resp.status == 200
    except urllib.error.HTTPError as e:
        print(f"  HTTPError {e.code}: {e.read()[:300]!r}")
        return False
    except Exception as e:
        print(f"  ERROR: {e!r}")
        return False


def synthesize(voice_id, text, out_path):
    body = {"voice_id": voice_id, "text": text, "nfe_step": 32, "speed": 1.0}
    print(f"[synth]    {voice_id} -> {out_path}")
    t0 = time.time()
    try:
        resp = post_json("/v1/synthesize", body, timeout=90)
        wav = resp.read()
        with open(out_path, "wb") as f:
            f.write(wav)
        print(f"  HTTP {resp.status} in {time.time()-t0:.1f}s :: {len(wav)} bytes")
        return resp.status == 200 and len(wav) > 50_000
    except urllib.error.HTTPError as e:
        print(f"  HTTPError {e.code}: {e.read()[:300]!r}")
        return False
    except Exception as e:
        print(f"  ERROR: {e!r}")
        return False


def main():
    results = {}
    for voice_id, candidates in VOICES.items():
        ok = False
        for cand in candidates:
            if register(voice_id, cand):
                ok = True
                results[voice_id] = {"registered_with": cand}
                break
            else:
                print(f"  -> retrying {voice_id} with next candidate")
                time.sleep(2)
        if not ok:
            results[voice_id] = {"registered_with": None, "error": "all candidates failed"}
            continue

        out_path = os.path.join(OUT_DIR, f"{voice_id}.wav")
        ok2 = synthesize(voice_id, TEST_LINE, out_path)
        results[voice_id]["synth_ok"] = ok2
        results[voice_id]["wav_path"] = out_path
        if os.path.exists(out_path):
            results[voice_id]["wav_bytes"] = os.path.getsize(out_path)

    print("\n=== SUMMARY ===")
    print(json.dumps(results, indent=2))
    failed = [v for v, r in results.items() if not r.get("synth_ok")]
    if failed:
        print(f"FAILED: {failed}")
        sys.exit(1)


if __name__ == "__main__":
    main()
