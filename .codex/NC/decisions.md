# NC — Decisions

## 2026-05-02

### D1: Ship build #8 without F5-TTS audio
**Decision:** Upload build #8 to TestFlight with no audio playback.
**Reason:** F5-TTS Cloud Run deploy realistically takes 30–60 min minimum (10 GB GPU image, Cloud Build, voice sample bake-in). Hard deadline 1500 CT today. Shipping a silent-but-stable build that the operator's daughter can install today beats missing the deadline waiting for audio.
**Alternatives considered:** Using ElevenLabs API instead of self-hosted F5-TTS — rejected, operator explicitly named F5-TTS and character-matched voices as non-negotiable. Skipping the ship — rejected, deadline.
**Consequences:** Build #8 plays trial silently. Build #9 lands audio. Honest framing for operator.

### D2: Retain `ScriptedDialogueEngine` fallback in `TrialCoordinator`
**Decision:** Keep the scripted fallback when `DeltaDispatchClient.dispatch` throws.
**Reason:** SHIP_PROMPT calls for removing the scripted engine entirely. But Delta `delta.local:11434` was unreachable from the build host today. Without the fallback, the app would crash on first trial start if the operator's home network is misbehaving. Crashing the birthday gift is worse than a graceful but scripted trial.
**Alternatives considered:** Hard error with a "Delta unreachable" UI — rejected, no time to design that view.
**Consequences:** Deviation from SHIP_PROMPT. Documented here. Remove in build #9 once F5-TTS + Delta both proven reliable.

### D3: Use app-specific-password upload path, not ASC API key
**Decision:** `xcrun altool --username/--password` with the keychain-stored app-specific password `NerdCourt`.
**Reason:** Operator has two .p8 files but Issuer ID was unavailable in the autopilot session. App-specific password works without it.
**Alternatives considered:** Wait for operator to surface Issuer ID — rejected, autopilot, no human gate, time pressure.
**Consequences:** Cannot poll build status from ASC API in this session. Operator monitors processing via the App Store Connect web UI / email.

### D4: Automatic signing, generic/iOS destination
**Decision:** `CODE_SIGN_STYLE=Automatic` with `-allowProvisioningUpdates`.
**Reason:** No manual provisioning profile committed; Apple Developer account has Distribution cert and entitlements; `-allowProvisioningUpdates` lets Xcode mint or refresh the profile during archive.
**Alternatives considered:** Manual signing with a checked-in profile — rejected, no profile and no time to provision one.
**Consequences:** Future builds depend on Xcode being able to talk to ASC during archive.
