# Unified Nerd Court — architecture proposal v0.1

**Status: proposal, not implemented.** This design reflects the source-backed graph and user product requirements recorded October 28, 2026.

## Plain-English system behavior

1. A viewer types a grievance and optional character names.
2. UATU identifies whether names refer to a fictional character, continuity-specific version, actor, role portrayed by an actor, or a real/historical person.
3. It finds the appropriate source evidence, distinguishes credible canon from interpretation, and asks for clarification only when essential to avoid a different individual.
4. UATU uses cross-portrayal archetype *gestalt* as background while compiling **separate, continuity-bounded variant profiles**. It creates temporary performance echoes, voice and visual briefs and a **versioned CastManifest**.
5. Nerd Court receives the evidence and cast, conducts structured prosecution/defense, performs character-specific dialogue and witnesses, produces a cited verdict and permits an earned comedic or dramatic finisher.
6. A production pipeline storyboards, records/synthesizes approved voices, animates shots, mixes, renders, encodes and checks a real video master.
7. Job services keep the viewer informed, manage costs, persist published assets and optionally preserve an exact echo snapshot for a sequel. The video is playable via browser, phone or television app.

## Proposed single-repo layout

```text
nerd-court/
  architecture/knowledge-graph/      # current source-backed architecture records
  architecture/contracts/            # versioned JSON interfaces (first migration unit)
  apps/
    web/                             # grievance, jobs, episode archive, player [PLANNED]
    tv/                              # streaming-platform client [PLANNED]
    ios-legacy/                      # move existing Swift code only after audit [PLANNED]
  services/
    identity/                        # classify and resolve actor / portrayal / variant [PLANNED]
    canon-evidence/                  # claim provenance, tiered canon, conflicts [PLANNED]
    uatu-casting/                    # variant psychology, ephemeral echoes, cast [PLANNED]
    courtroom/                       # adversarial trial, judge and finisher rules [PLANNED]
    showrunner/                       # scenes, timing, boards [PLANNED]
    media-render/                     # animation, sound, encoding, QC [PLANNED]
    jobs/                            # retries, idempotency, visibility [PLANNED]
  packages/
    contracts/                       # generated language bindings after schema review [PLANNED]
    shared-tests/                     # source-backed fixtures, no cross-variant leakage [PLANNED]
  infra/                              # deploy, access, secrets and storage policy [PLANNED]
  docs/                               # operational how-to and design decisions [PLANNED]
  Sources/, Tests/, convex/           # EXISTING Swift/Convex code, untouched on feature branch
```

The layout is **a target**, not a claim that these directories or components exist today. Do not migrate by mass-copying the old repos; use pinned-source references until a candidate module has a passing characterization test and known license.

## Identity contract

The identity hierarchy is `Archetype -> Variant -> EpisodeEcho`, with **parallel** entity types for performers and portrayals:

- **Archetype:** an evidence-aware gestalt across portrayals; may contain conflicting versions, explicitly tagged.
- **Variant:** fixed franchise, publisher, medium, universe, timeline, role, and era; exact source claims and relationship bounds.
- **Performer:** real actor/person, not equivalent to an authored character; `portrays` is a typed edge, not an `is` edge.
- **Portrayal:** an actor playing a role *in a named production* and, if applicable, within a specified fictional world.
- **EpisodeEcho:** temporary performance state pinned to one variant or portrayal, one episode and one profile revision. The underlying canon never mutates when fiction happens in court.

As an example, **Robert Downey Jr., MCU Tony Stark, Downey's Lewis Strauss portrayal, Downey's Charlie Chaplin portrayal, and a specifically chosen Doctor Doom portrayal are five distinct records** even if jokes intentionally connect them. Do not assume Doom is MCU Stark in disguise just because the performer overlaps.

## Data contracts to implement first

- `Grievance`: the allegation, named entities, user constraints, user-entered continuity hints and submission identifier.
- `EntityResolution`: entity kind, canonical ID, portrayal/actor mapping, evidence and ambiguity score.
- `VariantProfile`: locked variant keys, citations, observed traits, modeled psychology and inferred claims clearly separated.
- `CastManifest`: fixed episode ID, source/profile/voice/visual versions, roles, character-echo references, witnesses and provenance.
- `EvidenceLedger`: citation anchors, direct source material, strength and contradiction handling.
- `EpisodeJob`: explicit state transitions, inputs/outputs, failure, retries, cost, timing, artifact verification.
- `EpisodeArtifact`: decodable video renditions, synchronized audio, captions, media hashes, review status and publication URI.

## Boundaries that must not collapse

| Boundary | Contract |
|---|---|
| Archetype vs variant | Gesture toward archetype for interpretation; do not import unrelated history or speech |
| Variant vs performer | Link with `portrays`; never unify identities |
| Research vs performance | Fact selection and uncertainty completed before actors begin improvising |
| Episode improvisation vs source canon | Show-only events are in episode history, not canonical evidence |
| Runtime echo vs durable profile | Echo lives for a job; serialize only if reuse approved |
| Psychological inference vs observable canon | Mark estimates/hypotheses separately from cited actions |
| Sound/animation playback vs video file | A scene executing in SpriteKit is not proof of encoded streaming media |
| Completion flag vs acceptance | `SUCCESS` requires verified playable A/V output, not just a scripted transcript |

## Build order

**Phase A (current):** pin repos, construct knowledge graph and an explicit source/destination ledger, identify licensing and security exclusions.  
**Phase B:** define versioned contracts; implement and test classification, continuity resolution and source ledger on a curated cross-franchise fixture set.  
**Phase C:** integrate UATU deep assessment and a variant-exclusive compiler; test identity drift and echo lifecycle under restarts and crossover stimuli.  
**Phase D:** integrate court debate, an evidence-backed judge, scene plans, staff/guest roles and finisher choreography; validate a complete **text-and-shot-plan trial**.  
**Phase E:** implement actual animation, voice approvals, mixing, render/encode, captions and media validation; prove one complete A/V episode before scaling.  
**Phase F:** add web + TV distribution, durable jobs, budgets, caching, observability, live capacity and measured long-episode turnaround.

Each phase has its own acceptance tests; no phase is declared complete merely because a file or API route exists.

## Graph-first development rule

When a new module is merged:
1. Add its source/provenance and destination owner node.
2. Add observed import/call/data-flow edges after reviewing the actual code.
3. Add a corresponding executable test and runtime status.
4. Resolve discrepancies between aspirational README claims and implementation evidence.
5. Maintain pinning and ensure no secret, licensed binary, or unwanted memory scope travels between repos.
