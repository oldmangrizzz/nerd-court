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
