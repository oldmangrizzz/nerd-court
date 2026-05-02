# NC — Runbook

## Build (Simulator)
```
xcodegen generate
xcodebuild -project NerdCourt.xcodeproj -scheme NerdCourt \
    -destination 'generic/platform=iOS Simulator' build
```

## Archive + Export + Upload (TestFlight)
```
rm -rf build/NerdCourt.xcarchive build/TestFlight
xcodebuild archive \
    -project NerdCourt.xcodeproj \
    -scheme NerdCourt \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath build/NerdCourt.xcarchive \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic

xcodebuild -exportArchive \
    -archivePath build/NerdCourt.xcarchive \
    -exportPath build/TestFlight \
    -exportOptionsPlist ExportOptions.plist \
    -allowProvisioningUpdates

APPLE_APP_SPECIFIC_PASSWORD=$(security find-generic-password -a "$USER" -s "NerdCourt" -w)
xcrun altool --upload-app \
    --type ios \
    --file build/TestFlight/NerdCourt.ipa \
    --username "me@grizzlymedicine.org" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD"
```

## Bump build number
Edit `project.yml`, `targets.NerdCourt.settings.base.CURRENT_PROJECT_VERSION`, then `xcodegen generate`.

## Identities
- Apple Distribution: Robert Hanson (T5AFHQ4L9C)
- Apple Development: me@grizzlymedicine.org (APN4NS6YBF)

## Keys
- ASC .p8: `~/.appstoreconnect/private_keys/AuthKey_25WMCHVZV8.p8`, `AuthKey_XU67S2UAYS.p8` (Issuer ID unknown in this session).
- App-specific password: keychain `NerdCourt`, account `$USER`.

## GCP
- Project: `grizzly-helicarrier-586794` (NOT `grizzly-helicarrier`).
- Account: authenticated via `gcloud auth login` 2026-05-02.

## Convex
- `CONVEX_DEPLOY_KEY` env var present, payload `{"v2":"89d38dea4f834554b0712e5ee264c59e"}`.
- Deployment URL not in env. `Sources/Utils/AppConfig.swift` falls back to `https://fastidious-wolverine-481.convex.cloud` (stale, verify before relying).

## Delta
- Host: `delta.local:11434` (ATS-excepted in `project.yml`).
- Status check: `curl -m 5 http://delta.local:11434/api/tags`. Was unreachable on 2026-05-02 from this build host.

## XCTest runtime — recovery recipe (M2 8GB hang mitigation)
On this MacBook Air M2 8GB, `xcodebuild test` reproducibly hangs at 0% CPU after `CopySwiftLibs` finishes for the UITests-Runner app, before testmanagerd handoff. To retry on this host:
1. `xcrun simctl shutdown all`
2. Force-quit `CoreSimulatorService` via Activity Monitor (or `sudo kill -9 <PID>` after `pgrep CoreSimulatorService`).
3. `rm -rf ~/Library/Developer/Xcode/DerivedData/NerdCourt-*`
4. Reboot the Mac for cleanest result.
5. Run with the UITests target skipped:
   ```
   xcodebuild test \
       -project NerdCourt.xcodeproj \
       -scheme NerdCourt \
       -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
       -skip-testing:NerdCourtUITests \
       -only-testing:NerdCourtTests
   ```
The `-skip-testing:NerdCourtUITests` flag is the important one — it prevents building `NerdCourtUITests-Runner.app`, which is the last thing xcodebuild does before the hang. If it still hangs after a fresh reboot + DerivedData wipe, run on a host with ≥16 GB RAM. Hang is host-resource, not project.

Also free disk before retrying — Xcode 26 simulator install needs headroom. On 2026-05-02 the boot drive hit 100% during this session; clearing `build/` and DerivedData recovered ~900 MB.

## Production verification (live backends, no simulator required)
```
python3 scripts/regression/test_tts_service.py
python3 scripts/regression/test_convex_backend.py
```
19 tests total. All green = production gate. Hits Cloud Run TTS (`https://nerd-court-tts-219679773601.us-central1.run.app`) and Convex (`https://fastidious-wolverine-481.convex.cloud`).
