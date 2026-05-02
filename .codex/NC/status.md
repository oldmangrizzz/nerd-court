# NC — Status

**Updated:** 2026-05-02 16:15 CT
**Branch:** ship/v1-build10
**Build:** #10 uploaded to TestFlight (delivery UUID `5c9a8015-8a6c-4a93-abe8-f38759201848`).

## Voice (build #10 — wired live)
- Cloud Run `nerd-court-tts` v2 deployed: public + `X-API-Key` middleware.
- URL: `https://nerd-court-tts-219679773601.us-central1.run.app`
- iOS sends `X-API-Key` from `F5TTSApiKey` Info.plist value (project.yml).
- Smoke pre-archive: 401 unauthenticated, 200 audio/wav (92 KB, 22050 Hz mono PCM) in 3.5 s with key.
- 4 character voices (jason_todd / matt_murdock / jerry_springer / deadpool_nph) backed by piper-tts CC0.
- Local AVSpeechSynthesizer remains as fallback if endpoint unreachable.

## Backend
- Convex `episodes.ts` + `grievances.ts` already deployed; mutations/queries match schema.
- Python regression suite (`scripts/regression/`) 19/19 PASS against live backends.

## Outstanding
- ASC processing → "Ready to Test" (poll dashboard ~5–30 min).
- Add operator + family Apple IDs to Internal Testing group (manual via App Store Connect UI, fastest path).
- iOS XCTest runtime hang on M2 8 GB host = environmental (Q6); not gating ship.
- OllamaMaxClient still scripted mock — real Delta integration deferred.

## Caveats
- API key bundled in IPA (extractable). Acceptable for Internal TestFlight (≤25 testers); rotate + move to per-user OIDC for public release.
