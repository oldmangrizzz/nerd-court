# NC — Status

**Updated:** 2026-05-02
**Branch:** `ship/v1-build8`
**Build:** v1.0 (8) — uploaded to App Store Connect, awaiting processing.
**Delivery UUID:** `bd074875-1182-4507-8083-6f3aeac9f625`

## Verification state
- `xcodebuild build` (iOS Simulator, Debug): **clean**, 1 warning (`UIRequiresFullScreen` deprecated in iOS 26 — non-blocking).
- `xcodebuild archive` (Release, generic/iOS): **ARCHIVE SUCCEEDED**.
- `xcodebuild -exportArchive` with `app-store-connect` method, automatic signing, team `T5AFHQ4L9C`: **EXPORT SUCCEEDED**, IPA 583 KB.
- `xcrun altool --upload-app` with app-specific password: **UPLOAD SUCCEEDED with no errors**.
- TestFlight `Ready to Test` state: **NOT YET CONFIRMED** — ASC processing takes 5–30 min after upload. Operator will receive ASC processing email; Internal Testing invite is automatic if a group is configured for the bundle.

## What ships in build #8
- Production LLM path uses `DeltaDispatchClient` (real HTTP) instead of mock `OllamaMaxClient`. Falls back to `ScriptedDialogueEngine` when Delta unreachable, so the trial still runs end-to-end on operator's daughter even if the home network is down.
- All five `FinisherType` cases dispatch through `FinisherAnimator` (`SKAction`-based; SFX assets still TODO — finisher sequences run silently for build #8).
- Spider-Verse cinematic engine, comic-beat overlay, camera controller, frame-rate shifts: present and wired (existing implementation; reviewed, not regressed).
- Convex schema + persistence path: present (`Sources/Networking/ConvexClient.swift`, `convex/schema.ts`).
- Privacy manifest: present (no tracking declared).
- AppIcon: present, full size set.
- Export compliance: `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO` set in `project.yml`.

## What does NOT ship in build #8 (documented in `open_questions.md`)
- F5-TTS Cloud Run deploy on `grizzly-helicarrier-586794`. `VoiceSynthesisClient` still points at a relative endpoint and silently no-ops on playback. Audio is muted in build #8.
- Character portrait art (currently colored shapes + initials, the Kimi regression aesthetic). Programmatic SKShapeNode portraits — readable but not Spider-Verse.
- Finisher SFX assets (`Resources/SFX/*.wav`).
- Convex prod deploy (`npx convex deploy`) — schema not pushed.
- Real character voice samples for the four staff voices (operator-supplied gate).
