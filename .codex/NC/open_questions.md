# NC — Open Questions

## Q1: TestFlight `Ready to Test` state for build #8
**Status:** Open as of 2026-05-02 12:38 CT.
**What we know:** `xcrun altool` returned `UPLOAD SUCCEEDED with no errors` with delivery UUID `bd074875-1182-4507-8083-6f3aeac9f625`. ASC processing takes 5–30 min typical.
**Resolution path:** Operator checks App Store Connect → My Apps → NerdCourt → TestFlight. State will move from "Processing" to "Ready to Test" or "Invalid Binary" with a rejection reason. If invalid, capture reason verbatim and address in build #9.

## Q2: F5-TTS character voice reference samples
**Status:** Not yet sourced.
**Detail:** SHIP_PROMPT P1 step 3 names four reference WAVs the operator must record or supply: `jason_todd.wav`, `matt_murdock.wav`, `jerry_springer.wav`, `deadpool_nph.wav`, each ~15 s, paired with a transcript. Default F5-TTS voices are explicitly disallowed.
**Resolution path:** Operator records or sources before build #9 starts P1.

## Q3: Delta rotation harness reachability
**Status:** Unreachable from this build host on 2026-05-02 (`curl -m 5 http://delta.local:11434/api/tags` returned HTTP 000).
**Detail:** Production trial path uses `DeltaDispatchClient`. When Delta is down, `TrialCoordinator` falls back to `ScriptedDialogueEngine` (decision D2). Operator's daughter on her own network may or may not have Delta visible.
**Resolution path:** Verify `delta.local` is reachable from the iPhone running TestFlight build, or move Delta behind a public HTTPS endpoint, before build #9 removes the fallback.

## Q4: Convex production deployment URL
**Status:** Unknown.
**Detail:** `CONVEX_DEPLOY_KEY` is set, but its payload contains only an opaque ID, not a URL. `convex/_generated/` does not exist. `AppConfig.convexDeploymentURL` falls back to a hardcoded URL of unknown freshness.
**Resolution path:** Run `npx convex dev --once` or check operator's Convex dashboard to retrieve the canonical URL, then set in xcconfig / Info.plist before build #9.

## Q5: ASC Issuer ID
**Status:** Unknown in autopilot.
**Detail:** Two .p8 keys exist on disk but the Issuer ID needed to use them with `altool --apiKey/--apiIssuer` is not stored locally that we found. Build #8 used `--username/--password` instead. Issuer ID is required for the App Store Connect REST API (e.g., to programmatically add beta testers, query build state).
**Resolution path:** Operator copies Issuer ID from App Store Connect → Users and Access → Keys, stores in keychain or env.
