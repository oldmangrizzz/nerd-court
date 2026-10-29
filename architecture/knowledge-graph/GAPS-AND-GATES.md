# Gaps, decisive evidence and acceptance gates

## State labels

- **SOURCE CONFIRMED** — repository/path exists at a pinned SHA; selected behavior is visible in source.
- **DESIGN ONLY** — document claims or proposes a capability; not runtime proof.
- **USER REQUIREMENT** — the desired product behavior was stated by the principal.
- **NOT DEMONSTRATED** — no end-to-end evidence yet in the reviewed sources.
- **TEST REQUIRED** — an explicit pass/fail test has not been run.

These labels are not interchangeable. Documentation named `COMPLETE` or a version tag is not automatically an accepted deployment.

## Priority P0 — architectural blockers

| Blocker | Evidence | Proposed acceptance |
|---|---|---|
| Actor vs character identity collision | UATU's `CharacterProfile` mixes multiversal identity records; current Court guest generator accepts name/universe/role | A casting test distinguishes actor, portrayed character, historical person and role; names are never identity keys by themselves |
| Variant contamination | Original anchor export retains all multiversal identities under one anchor | Variant compiler refuses to import facts whose source variant is not selected; explicit crossover is a separate event |
| Gestalt vs variant mismatch | Grizzly Knights compiler says “full published canon, not adaptations”; new requirement says archetype gestalt crosses portrayals | Gold dossier is an interpreted reference; playable variant is resolved and tested on version-specific facts |
| Provenance / unverifiable canon claims | Swift ResearchNode calls in-process `CanonDatabase`; independent Convex retrieval path also exists | Contradictory, fabricated and weakly sourced statements get `Disputed` or `Unresolved`, and cannot silently determine verdict |
| Court judgment and comedy coupled | Historic blueprint scores canon/ethics/comedy; Python score evaluator accepts a bias | Evidence-based verdict record distinct from creative finisher; retained evidence ledger supports review |
| Persistent persona lifecycle | UATU assumes one permanent container/person, local/Convex memory | Echo session has explicit TTL, durable opt-in snapshot, canonical source immutability, no cross-case leakage |
| Silent scripted fallback | DebateNode falls back to `ScriptedDialogueEngine` and returns nonempty episode | Failure is reported as fallback / partial, not as an autonomously completed generative episode |
| No demonstrated video master | Existing Episode is transcript data and SpriteKit scene playback; no verified full encoding pipeline | Generated master file passes decoder, duration, sync, subtitles and representative visual/voice fidelity checks |

## Priority P1 — production blockers

| Blocker | Test required |
|---|---|
| Voice authenticity / rights | Verified usable voice route, voice identity consistency and approval to distribute chosen portrayal |
| Visual consistency | Same actor/variant across shots, no identity drift, rig/camera continuity |
| Scene duration and actual episode pacing | 15–30 minute continuous media file with meaningful scenes, not looped filler or a text-duration estimate |
| Dynamic witness casting | Model chooses relevant witnesses from provenance with no invented citations |
| Finisher timing / conditionality | No finisher if not earned by verdict or character behavior; no accidental scene collision |
| Production reproducibility | Exact source/model/asset revisions and deterministic seeds where supported |
| Cost / latency | Cold- and warm-path measurements of full render time and actual API/GPU cost; do not promise a couple minutes before measurements |
| Distribution | Publish playable master/renditions and serve them to web, phone, TV clients with proper media metadata |

## Acceptance cases

1. **Actor casting collision:** RDJ, MCU Tony Stark, the historical Lewis Strauss, his dramatized portrayal, Chaplin portrayal and one explicitly selected Doctor Doom variant remain distinct records with typed `portrays` links.
2. **Cross-media boundaries:** Earth-616 Spider-Man, an MCU Spider-Man and a separately selected animated variant are mutually isolated; same archetype is permitted only as reference.
3. **Uncertain canon:** Luke / Rey surname case must account for the film's Force-ghost scene and competing interpretations rather than writing guilt into the research prompt.
4. **Temporary echoes:** Create two simultaneous roles; assert disjoint scoped memory; fail/restart a job; resume with same pinned profile and no borrowed memories.
5. **Persona fidelity:** Under the same escalating emergency, Johnny, Peter, Maria and Tony should exhibit distinct sourced behavioral stress signatures; if not, mark evaluation failed rather than grading by writing style.
6. **Research contamination:** Wikipedia/Fandom text injection or inconsistent dates cannot rewrite authoritative evidence.
7. **Pipeline failure:** Removed voice model, failed render, disconnected Convex, insufficient storage, duplicate job and interrupted encoding must lead to bounded recovery/explicit failure.
8. **Video output:** A real encoded 15–30 minute episode with verified A/V, captions, shot continuity, inspectable source ledger and final asset URI.
9. **Distribution:** Same versioned media asset plays on web/phone/TV; playback is not a simulation status screen.
10. **Cost:** Measure model generations, animation frames, voice synthesis, render time, cloud usage and CDN transfer for each test case.

## What was actually verified in this graph preparation

- Six source repositories and precise commit heads.
- Exhaustive **tracked-file path** inventory for those six pinned trees, not file contents for every tracked file.
- Presence of 89 selected module paths, each cross-linked by an exact file-node bridge.
- Selected implementation definitions and source behavior in UATU, Grizzly Knights and Nerd Court.

**Not done:** full static call graph; complete dependency license/security audit; clone, build or execution of six source applications; running their original test suites; real character fidelity trials; rendering a playable television episode; measurements of turnaround/cost. Future work must not label those done without test evidence.
