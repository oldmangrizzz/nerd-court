# NC — Agent

**Project:** NerdCourt (NC) — iOS courtroom simulation, Spider-Verse cinematic aesthetic, autonomous 10–20 min trials, F5-TTS character voices, animated finishers, Convex persistence.

**Operator:** Robert "Grizzly" Hanson (EMT-P retired, GMRI founder).
**Team:** T5AFHQ4L9C (Apple Developer).
**Bundle ID:** `com.grizzlymedicine.nerdcourt`.

## Roles in this repo
- Architect — designs phases (blueprint = `nerd-court-blueprint.md`).
- Builder — implements; works on feature branches.
- Reviewer — verifies; runs full build/test before sign-off.
- Ops — archives, uploads, persists memory, deploys.

## Conventions
- Swift 6 strict concurrency.
- iOS deployment target 26.0, Xcode 26.5.
- xcodegen drives `NerdCourt.xcodeproj` from `project.yml`.
- ATS exception for `delta.local` (operator's home rotation harness).
- Tests live in `Tests/NerdCourtTests` and `Tests/NerdCourtUITests`.

## Hard rules (per AGENTS.md)
- No pseudocode, no fabricated APIs, no tool-failure fabrication.
- "Deployed" means TestFlight processed and accepting installs, verified.
- Scope-label every claim. Density is signal. No infantilization.
- Speak alongside, not above.
