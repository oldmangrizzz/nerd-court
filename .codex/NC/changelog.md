# NC — Changelog

## 2026-05-02 — v1.0 (8) ship to TestFlight
- Branch `ship/v1-build8` from master.
- Bumped `CURRENT_PROJECT_VERSION` 7 → 8.
- Production LLM path swapped from mock `OllamaMaxClient` to real `DeltaDispatchClient`.
- Removed duplicate `wormsEye` switch case.
- Export compliance flag added.
- `ExportOptions.plist` fixed for `app-store-connect` method.
- Archive + export + upload succeeded. ASC delivery UUID `bd074875-1182-4507-8083-6f3aeac9f625`.
- Audio, character art, Convex deploy, F5-TTS deploy: deferred to build #9 with documented gates.

## 2026-05-02 — Build #9 → TestFlight (Ops)
- **Delivery UUID:** 934eecff-5124-43f2-bdf3-f5013e289a98
- **Branch:** ship/v1-build9 (commit eaf or HEAD; pushed)
- **Shipped:**
  - AVSpeechSynthesizer audio fallback (sentinel URL routing, delegate completion)
  - LocalVoiceProfile per-Speaker iOS voice mapping
  - Spider-Verse layered SKShapeNode portraits (Jason/Matt/Jerry/Deadpool)
  - Procedural finisher SFX wired into all 5 finishers
  - project.yml: build 9, ITSAppUsesNonExemptEncryption=NO, F5TTSEndpoint key
- **Verified:** xcodebuild archive + export + altool upload all clean
- **Deferred → build #10:** F5-TTS Cloud Run, real voice samples, Convex prod deploy (key stale), CC0 SFX replacements
