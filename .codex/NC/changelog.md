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

## 2026-05-02 (post-deadline) — Production regression suite committed
- **Branch:** `ship/v1-build9` (commit `9f7debd`, pushed to origin)
- **Shipped:**
  - Python regression suite (`scripts/regression/`): live-backend tests against Cloud Run TTS + Convex. **19/19 PASS.**
  - Swift regression suite (`Tests/NerdCourtTests/`): EpisodeModel, FinisherAnimator, LocalVoiceProfile, CharacterPortraitNode. Compiles + builds clean.
- **Verified:** Python suite green against `https://nerd-court-tts-219679773601.us-central1.run.app` and `https://fastidious-wolverine-481.convex.cloud`. Build #9 live on TestFlight.
- **Deferred:** iOS XCTest runtime execution. Reproducible host-resource hang on this MacBook Air M2 8GB — `xcodebuild test` stalls at 0% CPU after `CopySwiftLibs`, before testmanagerd handoff. Documented as environmental in `open_questions.md` and `runbook.md`. Production gate is the live-backend Python suite + the shipped TestFlight build, both green.

## 2026-05-02 — Build #10 (post-deadline doubledown, "the daughter's demo deserves real voice")
- Cloud Run TTS service updated: `X-API-Key` middleware (`infra/f5tts/server.py`).
- Re-deployed `nerd-court-tts` revision `00002-8d8` with `--allow-unauthenticated` + env var `NERDCOURT_API_KEY`.
- VoiceSynthesisClient: new `apiKey` parameter; reads from `F5TTSApiKey` Info.plist; sends `X-API-Key` header.
- project.yml: `CURRENT_PROJECT_VERSION` 9 → 10; `F5TTSEndpoint` set to live URL; `F5TTSApiKey` added.
- Archive + export + altool upload SUCCEEDED. Delivery UUID `5c9a8015-8a6c-4a93-abe8-f38759201848`.
- Pre-upload verification: anonymous request returned 401; authenticated request returned 200 audio/wav (92 204 bytes, 22050 Hz, valid PCM, 3.5 s round-trip).

## 2026-05-02 21:53 CT — Build #12 (security hardening)

- NEW Sources/Security/InputSanitizer.swift
  - 10 hostile-input regex patterns: role markers, "ignore previous instructions",
    DAN/jailbreak preludes, code fences, ${...} placeholders, ANSI escapes
  - Strips control chars + zero-width + bidi-override scalars
  - Hard length caps: party 80, grievance 600
  - DoS guard: 4× pre-truncation before regex work
- IntakeScreen now sanitises plaintiff/defendant/grievance at submit chokepoint
  and blocks submit when sanitisation empties the field
- OllamaCloudClient wraps debate context in <USER_DATA>...</USER_DATA> with a
  SECURITY CONTRACT system block (defence-in-depth: even if sanitiser misses
  something, the LLM is told to treat the block as untrusted data)
- NEW Tests/NerdCourtTests/InputSanitizerTests.swift — 11/11 PASS
- project.yml: CURRENT_PROJECT_VERSION 11→12
- altool UPLOAD SUCCEEDED, ASC VALID, attached to Internal Testers group

## 2026-05-02 22:18 CT — Build #13 (cold-start self-heal)

- NEW Sources/Voice/VoiceRegistryReplay.swift
  - Async actor that GETs F5-TTS root catalogue and POSTs /v1/voices/register
    for any of the 4 staff voices missing from a cold-started Cloud Run instance
  - Manifest = same yt-search sources the regression suite proves work
  - Fails open: if endpoint unreachable, app keeps using AVSpeechSynthesizer fallback
- NerdCourtApp.init fires Task.detached(priority: .utility) to run replay on launch
- NEW Tests/NerdCourtTests/VoiceRegistryReplayTests.swift (3 tests, all green)
- project.yml: CURRENT_PROJECT_VERSION 12→13
- Combined sanitiser+replay test run: 14/14 PASS on iPhone 17 Simulator
- altool UPLOAD SUCCEEDED, ASC VALID, attached to Internal Testers group

## 2026-05-02 22:38 CT — Build #14 (crash fix + hardening)

**Root cause of #13 crash:** `INFOPLIST_KEY_<custom>` build settings are silently
ignored by Xcode unless the key is in Apple's allowlist. `OllamaApiKey`,
`F5TTSEndpoint`, `F5TTSApiKey` were never written into the generated Info.plist.
`AppConfig.ollamaCloudApiKey` returned `""`, the precondition in
`OllamaCloudClient.init` tripped → `EXC_BREAKPOINT` on every first trial.

**Fix:**
- NEW `Resources/RuntimeConfig.plist` (gitignored) — real bundle resource
  holding all API keys / endpoints. Verified shipped in `.app` bundle.
- NEW `Resources/RuntimeConfig.example.plist` (committed) — schema reference.
- `.gitignore`: added `Resources/RuntimeConfig.plist`.
- `Sources/Utils/AppConfig.swift` — `[String:String]` cache reads
  RuntimeConfig.plist; resolution order env → RuntimeConfig → Info.plist.
- `Sources/Networking/OllamaCloudClient.swift` — init now `throws
  OllamaCloudError.missingAPIKey` instead of preconditioning.
- `Sources/Store/TrialCoordinator.swift` — wraps init in do/catch; when LLM
  client unavailable, runs ScriptedDialogue fallback so the app never crashes.
- `Sources/Voice/VoiceSynthesisClient.swift` + `VoiceRegistryReplay.swift` —
  read F5-TTS config through `AppConfig`.
- `project.yml` — removed three custom INFOPLIST_KEY_* entries (silent no-ops).

**New hardening (folded in same build):**
- NEW `Sources/Security/LLMResponseSanitizer.swift` — strips leaked
  SECURITY CONTRACT, role markers, URLs, code fences from LLM output;
  caps 800 chars at sentence boundary. Wired into OllamaCloudClient.dispatch.
- NEW `Sources/Security/SubmissionRateLimiter.swift` — UserDefaults-backed
  30s cooldown + 20-per-24h-window cap; persists across launches.
- IntakeScreen: rate limiter consume on submit, user-visible message.

Tests: 27/27 green on iPhone 17 Simulator.
altool UPLOAD SUCCEEDED, ASC VALID, attached to Internal Testers group.
