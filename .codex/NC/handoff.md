# NC — Handoff

**From:** Claude Opus 4.7 (autopilot, all four roles, single session, 2026-05-02)
**To:** next session (build #9 work)

## What was done in this session
1. Created branch `ship/v1-build8` from master.
2. Bumped `CURRENT_PROJECT_VERSION` 7 → 8 in `project.yml`.
3. Added `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO` to `project.yml` (export compliance).
4. Fixed `ExportOptions.plist`: `method` → `app-store-connect`, added `destination: export`.
5. Removed duplicate `case .wormsEye` in `Sources/Animation/SpiderVerseEffects.swift` (compiler warning).
6. Replaced mock `OllamaMaxClient()` with `DeltaDispatchClient(deltaHost: AppConfig.deltaHost)` in `Sources/Store/TrialCoordinator.swift` — production now hits Delta over real HTTP.
7. Verified clean build in Simulator.
8. Archived Release for generic/iOS, exported IPA (583 KB), uploaded to App Store Connect via `altool` + app-specific password (in macOS keychain, service `NerdCourt`).
9. Seeded `.codex/NC/` memory.

## Files changed
- `project.yml`
- `Sources/Animation/SpiderVerseEffects.swift`
- `Sources/Store/TrialCoordinator.swift`
- `ExportOptions.plist`

## Verification evidence (verbatim)
- `** ARCHIVE SUCCEEDED **`
- `** EXPORT SUCCEEDED **`
- `UPLOAD SUCCEEDED with no errors / Delivery UUID: bd074875-1182-4507-8083-6f3aeac9f625`

## What is NOT verified
- TestFlight `Ready to Test` — uploaded, not yet processed. Operator must check ASC.
- Trial does not produce audio yet — `VoiceSynthesisClient` endpoint is a broken relative URL. F5-TTS not deployed.
- Character art is shapes+initials. Visually the Kimi regression aesthetic. Honest framing for the operator.
- Convex schema not pushed to prod. Episode persistence will fail at runtime if deploy URL stale.

## Next session starts here
Build #9 priorities (in order):
1. Deploy F5-TTS to Cloud Run on `grizzly-helicarrier-586794` (infra/f5tts/ scaffolding TBD).
2. Wire `F5TTSEndpoint` Info.plist key + xcconfig + `GoogleAuthClient.swift` JWT signer.
3. Replace `CharacterPortraitNode` shapes with Spider-Verse stylized SKSpriteNode portraits.
4. Source/record character voice samples (operator gate).
5. `npx convex deploy --prod` and update `AppConfig.convexDeploymentURL`.
6. Add finisher SFX (CC0 freesound.org) to `Resources/SFX/`.
