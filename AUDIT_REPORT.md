# Nerd Court iOS App — Audit Report

**Date:** 2026-05-01  
**Branch:** `master`  
**Scope:** `/Users/grizzmed/nerd-court`

---

## 1. Secrets / Hardcoded Tokens

| File | Line(s) | Finding |
|------|---------|---------|
| `Sources/Voice/VoiceSynthesisClient.swift` | 81–82 | **Hardcoded Bearer token** in `Authorization` header for Ollama Cloud API |
| `Sources/Networking/ConvexClient.swift` | 7 | **Hardcoded Convex deployment URL**: `https://fastidious-wolverine-481.convex.cloud` |
| `Sources/Tests/NerdCourtTests/ConvexClientTests.swift` | 32, 94, 141 | Hardcoded Convex deployment URL repeated in test assertions |
| `project.yml` | 29 | **Hardcoded Apple Development Team ID**: `T5AFHQ4L9C` |
| `project.yml` | 7 | Hardcoded `bundleIdPrefix`: `com.grizzlymedicine` |
| `.xcode-cloud/workflow.yml` | 38–39 | Uses GitHub secrets (`secrets.APPLE_ID`, `secrets.APPLE_APP_SPECIFIC_PASSWORD`) — **good practice** |

**Risk Summary:** The Bearer token and Convex URL are embedded in source control. The token should be injected via environment variables, a secrets manager, or `xcconfig`. The deployment URL should also be configurable per environment.

---

## 2. Monetization / Subscription Traces

**Result: NONE FOUND.**

Searches for `StoreKit`, `InAppPurchase`, `IAP`, `subscription`, `membership`, `paywall`, `premium`, `paid`, `pricing`, `revenue`, `upsell`, `voice pack`, and `pack` returned no evidence of monetization code.

The only hits were false positives:
- `project.yml` line 13: empty `packages: {}` (SPM packages, not product packs)
- `Sources/Research/EvidenceAssembler.swift` line 57: comment reference to "evidence package"

---

## 3. Account / Login / Signup Traces

**Result: NO FULL AUTH SYSTEM FOUND.**

The app does not implement login, signup, or real user authentication. The only account-related traces are:

| File | Line(s) | Finding |
|------|---------|---------|
| `Sources/Views/IntakeScreen.swift` | 122 | `submittedBy: "anonymous"` — hardcoded anonymous identifier |
| `Sources/Models/Grievance.swift` | 8 | `submittedBy: String` field on Grievance model |
| `convex/schema.ts` | 9 | `submittedBy: v.string()` field in `grievances` table |

There is no `userId`, no auth provider integration, no profile management, and no session logic.

---

## 4. Duplicate / Conflicting Type Definitions

Several types are defined multiple times with **different shapes**, creating serious compilation risk.

### `OllamaMaxClient` — 3 definitions (class/actor name collision)
| File | Type | Details |
|------|------|---------|
| `Sources/Debate/OllamaMaxClient.swift` | `final class OllamaMaxClient` | Dispatches to Delta harness; uses `OllamaMaxDispatchRequest/Response` |
| `Sources/Networking/ModelRotationClient.swift` | `final class OllamaMaxClient` | Mock-LLM client with model rotation tiers (T1/T2/T3) |
| `Sources/Networking/OllamaMaxClient.swift` | `actor OllamaMaxClient` | Actor-based client for Delta rotation harness |

**Risk:** Swift will refuse to compile three types with the same fully-qualified name.

### `DebatePhase` — 2+ definitions (incompatible enums)
| File | Type | Cases |
|------|------|-------|
| `Sources/Debate/TurnManager.swift` | `enum DebatePhase` | `openingStatement`, `plaintiffArgument`, `defendantArgument`, `crossExamination`, `closingStatement`, `verdict`, `finished` |
| `Sources/Models/GuestCharacter.swift` | `enum DebatePhase` | `intake`, `canonResearch`, `openingStatement`, `witnessTestimony`, `crossExamination`, `evidencePresentation`, `objections`, `closingArguments`, `juryDeliberation`, `verdictAnnouncement`, `finisherExecution`, `postTrialCommentary`, `deadpoolWrapUp`, `complete` |

**Risk:** These two enums share a case (`openingStatement`) but have otherwise completely disjoint case lists. Any file importing both will fail to compile.

### `CanonResearchResult` — 3 definitions (different shapes)
| File | Shape |
|------|-------|
| `Sources/Research/CanonResearchService.swift` | `query: String`, `sources: [CanonSource]`, `summary: String`, `researchedAt: Date` |
| `Sources/Debate/DebateEngine.swift` | `sources: [CanonSource]`, `keyFacts: [String]`, `plaintiffEvidence: [String]`, `defendantEvidence: [String]` |
| `Sources/Research/EvidenceAssembler.swift` | `plaintiffArguments: [String]`, `defendantArguments: [String]`, `sources: [String]` |

### `CanonSource` — 3 definitions
| File | Shape |
|------|-------|
| `Sources/Research/CanonResearchService.swift` | `id, title, snippet, url: URL, attribution, relevanceScore: Double` |
| `Sources/Debate/DebateEngine.swift` | `id, title, url: String, excerpt: String` |
| `Sources/Research/EvidenceAssembler.swift` | No definition; relies on sibling-file assumption |

### `CameraAngle` — 3 definitions
| File | Cases |
|------|-------|
| `Sources/Models/CinematicFrame.swift` | `lowAngle`, `highAngle`, `dutchAngle`, `closeUp`, `mediumShot`, `wideShot`, `overShoulder`, `pov`, `birdsEye`, `wormsEye` |
| `Sources/Animation/SpiderVerseEffects.swift` | `closeUp`, `mediumShot`, `wideShot`, `dutchAngle`, `overhead`, `lowAngle`, `extremeCloseUp` |
| `Sources/Animation/CameraController.swift` | `wideShot`, `closeUp`, `overShoulder`, `lowAngle`, `dutchAngle`, `pov` |

### `FrameRateShift` — 2 definitions
| File | Cases |
|------|-------|
| `Sources/Models/CinematicFrame.swift` | `normal`, `slowMotion`, `fastMotion`, `stutter`, `freezeFrame` |
| `Sources/Animation/SpiderVerseEffects.swift` | `normal`, `slowMo`, `fastForward`, `freezeFrame`, `reverse` |

### `CinematicFrame` — 2 definitions (different shapes)
| File | Shape |
|------|-------|
| `Sources/Models/CinematicFrame.swift` | Full struct with `cameraAngle`, `intensity`, `colorPalette`, `benDayDots`, `speedLines`, `glitch`, `frameRateShift`, `sting` |
| `Sources/Models/SpeechTurn.swift` | Minimal struct with `effectType: CinematicEffect`, `duration: Double`, `intensity: Double` |

### `displayName` Extensions — Multiple, but on distinct types
No direct naming conflicts, but scattered across many files:
- `Speaker.displayName` — `Sources/Models/Speaker.swift:10`
- `DebatePhase.displayName` — `Sources/Views/CourtroomView.swift:292`
- `Verdict.Ruling.displayName` — `Sources/Views/EpisodeBrowser.swift:171`, `Sources/Views/EpisodePlayer.swift:222` (duplicate extensions across files)
- `FinisherType.displayName` — `Sources/Views/EpisodeBrowser.swift:181`, `Sources/Views/EpisodePlayer.swift:236` (duplicate extensions across files)
- `Franchise.displayName` — `Sources/Views/Components/FranchiseTagSelector.swift:18`
- `CharacterSlot.displayName` (computed property) — `Sources/Views/Components/CharacterSlot.swift:9`
- `FinisherExecutor.displayName(for:)` — `Sources/Animation/FinisherExecutor.swift:433`

---

## 5. Test Target Configuration

**CRITICAL ISSUE:** `project.yml` does **not** define a separate test target.

- The `NerdCourt` app target sources include `Sources` (recursive)
- Test files live under `Sources/Tests/NerdCourtTests/` and `Sources/Tests/NerdCourtUITests/`
- Because `Sources` is included wholesale, **test code is compiled into the app binary**

**Test files affected:**
- `Sources/Tests/NerdCourtTests/ConvexClientTests.swift`
- `Sources/Tests/NerdCourtTests/VoiceSynthesisServiceTests.swift`
- `Sources/Tests/NerdCourtTests/GuestCharacterGeneratorTests.swift`
- `Sources/Tests/NerdCourtTests/DebateEngineTests.swift`
- `Sources/Tests/NerdCourtUITests/CourtroomFlowUITests.swift`

**Recommendation:** Move tests out of `Sources` into a top-level `Tests/` directory and define a dedicated `NerdCourtTests` target in `project.yml`.

---

## 6. Microphone Permission

| File | Line | Finding |
|------|------|---------|
| `project.yml` | 34 | `INFOPLIST_KEY_NSMicrophoneUsageDescription` is declared |

**However:** No actual microphone recording code was found. `AVAudioSession` appears only for audio **playback**:
- `Sources/Views/EpisodePlayer.swift` lines 35–36: sets category `.playback`, mode `.default`
- `Sources/Voice/VoiceSynthesisClient.swift` line 26: sets category `.playback`, mode `.spokenAudio`

**Risk:** The microphone usage description is present, but the app does not appear to record audio. If the app does not record, the description should be removed to avoid App Review rejection. If it does record, the recording code was not found during this audit.

---

## 7. Convex Schema Alignment

**Schema file:** `convex/schema.ts`

**Tables found:**
1. `grievances`
2. `episodes`
3. `guestCharacters`
4. `canonResearch`
5. `characters` ← **NOT in expected set**

**Unexpected table:** `characters` (line 48+) defines static courtroom characters (`plaintiffLawyer`, `defenseLawyer`, `judge`, `announcer`). This was not listed in the expected schema set.

**Field-level alignment:**
- `grievances.submittedBy` → present in schema, model, and IntakeScreen (hardcoded to `"anonymous"`)
- `episodes` fields broadly match Swift `Episode` model
- `episodes.finisherType` exists in schema as optional string; Swift uses `FinisherType?`
- `guestCharacters.usedInEpisodeIds` is `[String]` in both schema and model

**No account-related fields** beyond `submittedBy` were found in the schema.

---

## 8. Unsafe Casts

| File | Line | Finding |
|------|------|---------|
| `Sources/Tests/NerdCourtTests/ConvexClientTests.swift` | 205 | `nonisolated(unsafe) static var requestHandler` — Swift 6 unsafe isolation suppression |

No instances of `as any`, `as!`, or general `unsafe` keyword usage were found in production Swift files. The only unsafe construct is in test code to bypass Swift 6 concurrency checking for a mock URL protocol.

---

## Summary of Critical Issues

1. **Hardcoded Bearer token** in `VoiceSynthesisClient.swift` — rotate and move to secrets management
2. **Hardcoded Convex deployment URL** across client and tests — should be environment-configurable
3. **Duplicate type definitions** for `OllamaMaxClient`, `DebatePhase`, `CanonResearchResult`, `CanonSource`, `CameraAngle`, `FrameRateShift`, and `CinematicFrame` — will cause compilation failures
4. **Test files compiled into app target** due to lack of separate test target in `project.yml`
5. **Microphone usage description declared without apparent recording functionality** — App Review risk
6. **Hardcoded Apple Team ID** in `project.yml` — not a secret, but not portable across teams

---
*End of audit report.*
