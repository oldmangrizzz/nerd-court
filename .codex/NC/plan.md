# NC — Plan

## Build #8 (this session) — DONE / shipped to ASC
P0 bootstrap, P3 production LLM swap, P7 archive + export + upload.

## Build #9 (next session) — target: complete the Spider-Verse promise
- P1 F5-TTS Cloud Run deploy on `grizzly-helicarrier-586794`.
- P1.5 `GoogleAuthClient.swift` ES256 JWT signer for service-account auth.
- P1.6 `VoiceSynthesisClient` endpoint via `Config.xcconfig` Info.plist key.
- P2 Spider-Verse character portraits — programmatic SKSpriteNode + shader stylization.
- P4 finisher SFX library (CC0 sources) wired into `FinisherAnimator`.
- P5 cinematic engine visual review via `xcrun simctl io booted recordVideo`.
- P6 `npx convex deploy --prod` + URL plumbing.
- P7 build #9 → TestFlight, repeat.

## Gates that block build #9
- 4 character voice reference WAVs (operator records or sources).
- Delta `delta.local:11434` reachability from build host.
- ASC API Issuer ID (unlocks polled build status + beta-tester API).
