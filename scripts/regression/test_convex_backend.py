"""Production regression tests for the deployed Convex backend.

Run:
    CONVEX_URL=https://fastidious-wolverine-481.convex.cloud \
    pytest scripts/regression/test_convex_backend.py -v

Hits the live deployment. Failure = production data layer is broken.
"""
from __future__ import annotations

import json
import os
import time
import uuid
from typing import Any

import pytest
import requests

CONVEX_URL = os.environ.get("CONVEX_URL", "https://fastidious-wolverine-481.convex.cloud")


def _mutation(path: str, args: dict[str, Any]) -> Any:
    resp = requests.post(
        f"{CONVEX_URL}/api/mutation",
        headers={"Content-Type": "application/json"},
        data=json.dumps({"path": path, "args": args, "format": "json"}),
        timeout=20,
    )
    assert resp.status_code == 200, f"{path} HTTP {resp.status_code}: {resp.text[:200]}"
    body = resp.json()
    assert body.get("status") == "success", body
    return body["value"]


def _query(path: str, args: dict[str, Any] | None = None) -> Any:
    resp = requests.post(
        f"{CONVEX_URL}/api/query",
        headers={"Content-Type": "application/json"},
        data=json.dumps({"path": path, "args": args or {}, "format": "json"}),
        timeout=20,
    )
    assert resp.status_code == 200, f"{path} HTTP {resp.status_code}: {resp.text[:200]}"
    body = resp.json()
    assert body.get("status") == "success", body
    return body["value"]


def test_grievance_submit_round_trip() -> None:
    marker = f"regression-{uuid.uuid4().hex[:8]}"
    gid = _mutation(
        "grievances:submit",
        {
            "plaintiff": "Jason Todd",
            "defendant": "DC Editorial",
            "grievanceText": f"Canon violation: {marker}",
            "franchise": "DC",
        },
    )
    assert isinstance(gid, str) and len(gid) > 10
    fetched = _query("grievances:getById", {"id": gid})
    assert fetched is not None
    assert fetched["plaintiff"] == "Jason Todd"
    assert fetched["status"] == "pending"
    assert marker in fetched["grievanceText"]
    _mutation("grievances:setStatus", {"id": gid, "status": "decided"})
    after = _query("grievances:getById", {"id": gid})
    assert after["status"] == "decided"


def test_episode_insert_persists_full_payload() -> None:
    grievance_id = _mutation(
        "grievances:submit",
        {
            "plaintiff": "Matt Murdock",
            "defendant": "Frank Castle",
            "grievanceText": "Vigilante methodology dispute",
            "franchise": "Marvel",
        },
    )
    transcript = [
        {"speaker": "matt", "text": "The defendant operates outside the law.", "ts": 0.0},
        {"speaker": "jerry", "text": "Spicy! Roll the tape.", "ts": 4.2},
    ]
    episode_id = _mutation(
        "episodes:insert",
        {
            "grievanceId": grievance_id,
            "transcript": transcript,
            "verdict": {"forPlaintiff": True, "reasoning": "Canon-supported"},
            "plaintiffArguments": ["Daredevil testimony"],
            "defendantArguments": ["Punisher counter-claim"],
            "comicBeats": ["Daredevil 181", "Punisher MAX 1"],
            "durationSeconds": 720.0,
            "finisherType": "gavelOfDoom",
        },
    )
    assert isinstance(episode_id, str)
    fetched = _query("episodes:getById", {"id": episode_id})
    assert fetched is not None
    assert fetched["grievanceId"] == grievance_id
    assert fetched["durationSeconds"] == 720.0
    assert fetched["finisherType"] == "gavelOfDoom"
    assert fetched["viewCount"] == 0
    assert len(fetched["transcript"]) == 2


def test_view_count_increments() -> None:
    grievance_id = _mutation(
        "grievances:submit",
        {
            "plaintiff": "Jerry",
            "defendant": "Crowd",
            "grievanceText": "Final thought theft",
            "franchise": "TV",
        },
    )
    episode_id = _mutation(
        "episodes:insert",
        {
            "grievanceId": grievance_id,
            "transcript": [],
            "plaintiffArguments": [],
            "defendantArguments": [],
            "comicBeats": [],
            "durationSeconds": 600.0,
        },
    )
    n1 = _mutation("episodes:incrementViewCount", {"id": episode_id})
    n2 = _mutation("episodes:incrementViewCount", {"id": episode_id})
    assert n1 == 1
    assert n2 == 2


def test_listRecent_returns_descending_by_generated() -> None:
    rows = _query("episodes:listRecent", {"limit": 5})
    assert isinstance(rows, list)
    assert len(rows) > 0
    timestamps = [r["generatedAt"] for r in rows]
    assert timestamps == sorted(timestamps, reverse=True)


def test_guest_character_upsert_idempotent() -> None:
    name = f"guest-{uuid.uuid4().hex[:6]}"
    payload = {
        "name": name,
        "universe": "Marvel",
        "role": "witness",
        "voiceId": "guest",
        "personalityPrompt": "Speaks in haiku.",
    }
    a = _mutation("guestCharacters:upsert", payload)
    b = _mutation("guestCharacters:upsert", {**payload, "personalityPrompt": "Speaks in sonnets."})
    assert a == b
    fetched = _query("guestCharacters:findByName", {"name": name})
    assert fetched["personalityPrompt"] == "Speaks in sonnets."


def test_pending_listing_includes_new_grievances() -> None:
    marker = f"pending-{uuid.uuid4().hex[:6]}"
    gid = _mutation(
        "grievances:submit",
        {
            "plaintiff": "Deadpool",
            "defendant": "Fourth Wall",
            "grievanceText": marker,
            "franchise": "Marvel",
        },
    )
    pending = _query("grievances:listPending", {})
    ids = {row["_id"] for row in pending}
    assert gid in ids


def test_query_latency_under_budget() -> None:
    start = time.monotonic()
    _query("episodes:listRecent", {"limit": 10})
    elapsed = time.monotonic() - start
    assert elapsed < 3.0, f"listRecent latency {elapsed:.2f}s exceeds 3s budget"
