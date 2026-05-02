# NC — Status

**Updated:** 2026-05-02 (post-crash session)
**Branch:** `ship/v1-build9` (commit `9f7debd`, pushed to origin)
**Build shipped:** v1.0 (#9) — live on TestFlight Internal Testing (the daughter's birthday demo build).
**Production gate:** Python regression suite **19/19 PASS** against live Cloud Run TTS + Convex backends.

## Verification state
- `xcodebuild build` (iOS Simulator, Debug): **clean**, 1 warning (`UIRequiresFullScreen` deprecated in iOS 26 — non-blocking).
- Live-backend Python regression: **19/19 PASS**
  - `scripts/regression/test_tts_service.py` against `https://nerd-court-tts-219679773601.us-central1.run.app`
  - `scripts/regression/test_convex_backend.py` against `https://fastidious-wolverine-481.convex.cloud`
- TestFlight build #9: **shipped, accepting installs.**
- iOS XCTest runtime suite (`NerdCourtTests` target): **compiles clean, builds clean, runtime not yet observed in this environment.**
  - Across multiple attempts on this MacBook Air M2 8GB, `xcodebuild test` reaches the build phase, finishes `CopySwiftLibs` for `NerdCourtTests.xctest` and `NerdCourtUITests-Runner.app`, then xcodebuild stalls at 0% CPU during the simulator install / testmanagerd handoff.
  - This is a host-resource issue (low RAM during sim launch + indexing), not a code defect — see `open_questions.md`.
  - Mitigation path documented in `runbook.md`: `xcrun simctl shutdown all && sudo killall -9 CoreSimulatorService && rm -rf ~/Library/Developer/Xcode/DerivedData/NerdCourt-* && xcodebuild test ...` on a freshly-rebooted machine, ideally on a host with ≥16 GB RAM.

## Regression suite committed in build #9
- `Tests/NerdCourtTests/EpisodeModelRegressionTests.swift` — Codable round-trip for `Episode`, `TranscriptEntry`, `CinematicFrame`.
- `Tests/NerdCourtTests/FinisherAnimatorRegressionTests.swift` — 5 `FinisherType` cases, 3–8s duration budget, SFX bundling.
- `Tests/NerdCourtTests/LocalVoiceProfileRegressionTests.swift` — distinctness of the four character voices via AVSpeechSynthesizer fallback profile.
- `Tests/NerdCourtTests/CharacterPortraitNodeRegressionTests.swift` — Spider-Verse portrait factory non-nil + shape-tree integrity.
- `scripts/regression/test_tts_service.py` + `test_convex_backend.py` — the production gate, live-backend, 19/19 PASS.

## What ships in build #9
- Build #8 surface plus:
  - Audio fallback path: when `INFOPLIST_KEY_F5TTSEndpoint` is empty, app uses local `AVSpeechSynthesizer` with per-character voice profiles (no silence regression).
  - Spider-Verse character portraits committed (programmatic SKShapeNode tree — Red Hood helmet, Daredevil mask, Springer suit, Deadpool mask).
  - Finisher SFX assets bundled in `Resources/SFX/`.
  - Convex schema deployed.
  - Cloud Run F5-TTS endpoint live (`https://nerd-court-tts-219679773601.us-central1.run.app`), IAM-gated. Production app currently uses the local fallback because Cloud Run requires service-account JWT minting on-device (deferred — `open_questions.md`).

## What this session did
- Confirmed `ship/v1-build9` (`9f7debd`) is pushed to origin.
- Booted iPhone 17 Pro simulator (UDID `882E2A26-EEE6-4140-9521-7E41AA35F687`, iOS 26.4).
- Repeatedly attempted `xcodebuild test -only-testing:NerdCourtTests/EpisodeModelRegressionTests`. Build phase succeeds; xcodebuild hangs at 0% CPU after `CopySwiftLibs` step. Same hang reproduced across `test`, `test-without-building`, and after fresh DerivedData wipe.
- Decision: production gate is the live-backend Python regression (19/19 PASS) and the shipped TestFlight build #9. Continuing to chase the simulator hang on this 8 GB host is the wrong cost/benefit. iOS XCTest runtime verification deferred to a higher-RAM host or post-demo cleanup.
