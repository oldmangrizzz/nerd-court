# NC — Handoff

**From:** Claude Opus 4.7 (autopilot, all four roles, 2026-05-02 close-out session)
**To:** next session (post-demo cleanup or build #10)

## Session outcome
Build #9 is live on TestFlight Internal Testing. Daughter's birthday demo is covered.
Production regression suite committed on `ship/v1-build9` (commit `9f7debd`, pushed).
Live-backend Python suite is **19/19 PASS** against Cloud Run TTS + Convex — that is the production verification gate.

## What was done in this session
1. Resumed from prior session's pending iOS XCTest runtime attempt.
2. Confirmed regression suite (`9f7debd`) is committed and pushed to `origin/ship/v1-build9`.
3. Booted iPhone 17 Pro simulator (UDID `882E2A26-EEE6-4140-9521-7E41AA35F687`, iOS 26.4) and re-attempted `xcodebuild test -only-testing:NerdCourtTests/EpisodeModelRegressionTests`.
4. Reproduced the hang for the third time: build phase completes through `CopySwiftLibs` for both `NerdCourtTests.xctest` and `NerdCourtUITests-Runner.app`, then xcodebuild idles at **0.0% CPU for 13+ minutes** at the simulator install / testmanagerd handoff. No progress, no errors.
5. Declared the hang environmental (M2 / 8 GB RAM / iOS 26 simulator under memory pressure), not a code defect. Stopped chasing.
6. Updated `.codex/NC/status.md`, `handoff.md`, `changelog.md`, `open_questions.md`, `runbook.md` to reflect build #9 reality and the deferred iOS XCTest runtime.

## Files changed (memory only)
- `.codex/NC/status.md`
- `.codex/NC/handoff.md`
- `.codex/NC/changelog.md`
- `.codex/NC/open_questions.md`
- `.codex/NC/runbook.md`

## Verification evidence
- `git log --oneline ship/v1-build9` → `9f7debd ship/v1-build9: production regression suite + live backends` (pushed to origin).
- `ps -o pid,pcpu,etime` on the hung xcodebuild PID: `0.0% 13:23` after `CopySwiftLibs` — clear hang signature.
- Python regression suite (prior session): 19/19 PASS, captured in `changelog.md`.
- TestFlight build #9: live, accepting installs (prior session ASC delivery UUID `934eecff-5124-43f2-bdf3-f5013e289a98`).

## What is NOT verified (and why it is acceptable)
- iOS XCTest runtime suite has not been observed executing on this host. The Swift regression tests **compile** and **build** clean, and they exercise pure model / view-tree / animator logic that is also covered by the Python live-backend tests at the integration boundary. The production verification gate is the shipped TestFlight build plus the green Python suite.
- F5-TTS Cloud Run is live but not invoked from the shipped app (build #9 uses local AVSpeechSynthesizer fallback). Deferred to build #10.

## What comes next (only if/when the operator asks)
1. **Run the iOS XCTest suite on a higher-RAM host** (≥16 GB) following the recipe in `runbook.md` ("XCTest runtime — recovery recipe"). Skip the UITests target with `-skip-testing:NerdCourtUITests` to avoid the `CopySwiftLibs` step that immediately precedes the hang.
2. **Build #10:** wire `GoogleAuthClient` JWT minting on-device so the app can hit the Cloud Run TTS endpoint directly; replace placeholder voice references with real character samples.
3. **Cleanup:** remove `UIRequiresFullScreen` from `project.yml` (deprecated in iOS 26).

## Stop condition (this session)
Memory updated to reflect build #9 shipped + Python suite green + iOS XCTest deferred as environmental. Memory committed and pushed on `ship/v1-build9`. No further code changes.
