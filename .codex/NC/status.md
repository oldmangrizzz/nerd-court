# Status — Build #14 SHIPPED (crash fix + hardening)

Branch: ship/v1-build11
Build: 14 (CFBundleVersion=14, MarketingVersion=1.0)
ASC processingState: VALID
TestFlight Internal Testing group: Nerd Court Internal Testers — attached
Delivery UUID: 63df81a5-b442-441b-ba42-078dc3fd32ee

CRITICAL FIX: build #13 crashed on first trial start with EXC_BREAKPOINT in
OllamaCloudClient.init — INFOPLIST_KEY_OllamaApiKey is silently ignored by
Xcode for non-Apple keys, so AppConfig.ollamaCloudApiKey returned empty and
the precondition tripped.

Build #14 ships:
  - Resources/RuntimeConfig.plist (gitignored) bundle resource holding
    OllamaApiKey, F5TTSEndpoint, F5TTSApiKey, ConvexDeploymentURL
  - AppConfig.runtimeConfig in-memory cache reads it; falls back to env then
    Info.plist
  - OllamaCloudClient.init now throws OllamaCloudError.missingAPIKey instead
    of preconditioning — TrialCoordinator catches and runs ScriptedDialogue
    fallback, app keeps running
  - Secrets removed from project.yml (still in git history but no new exposure)
  - LLMResponseSanitizer added on the response path (defence in depth)
  - SubmissionRateLimiter added to IntakeScreen (30s cooldown / 20-per-day cap)

Tests: 27/27 PASS on iPhone 17 Sim
  - InputSanitizerTests (11)
  - LLMResponseSanitizerTests (8)
  - SubmissionRateLimiterTests (5)
  - VoiceRegistryReplayTests (3)

Last updated: 2026-05-02 22:38 CT
