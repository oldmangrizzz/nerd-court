# NC — Open Questions

## Q1: TestFlight `Ready to Test` state for build #8
**Status:** Resolved 2026-05-02 — superseded by build #9.
**What we know:** `xcrun altool` returned `UPLOAD SUCCEEDED with no errors` with delivery UUID `bd074875-1182-4507-8083-6f3aeac9f625`. Build #8 was processed; build #9 (delivery UUID `934eecff-5124-43f2-bdf3-f5013e289a98`) followed and is the current TestFlight artifact.

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

## Q6: iOS XCTest runtime on this build host
**Status:** Open / deferred (not blocking demo).
**Detail:** On 2026-05-02 across three session attempts, `xcodebuild test` on this MacBook Air M2 8GB reproducibly hangs at 0% CPU after `CopySwiftLibs` finishes for `NerdCourtUITests-Runner.app`. Build phase clean, simulator booted, testmanagerd alive, but xcodebuild never hands off. Same hang signature each time. Disk also hit 100% during the session — root cause is most likely a combination of 8 GB RAM pressure and Xcode-26 simulator-install needing more disk headroom than was available.
**What we know:** Code compiles and builds clean. Python live-backend regression suite (19/19 PASS) is the production gate. TestFlight build #9 is shipped and accepting installs. The hang is environmental.
**Resolution path:** Either (a) run the suite on a ≥16 GB host with the recipe in `runbook.md` ("XCTest runtime — recovery recipe"), or (b) accept the live-backend Python suite + shipped TestFlight build as the production verification gate (current decision). Not blocking the daughter's demo.
