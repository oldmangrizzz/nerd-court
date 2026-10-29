# Consolidation ledger v0.1

**This is a decision ledger, not a claim that code has been migrated or deployed.** Each candidate is linked to its pinned source tree. Entries with `REVIEW` or `DEFER` must not be copied automatically.

| Origin | Component | Disposition | Destination | Reason / next gate |
|---|---|---|---|---|
| UATU Engine | Genesis orchestrator and character agent | **ADAPT** | `services/identity` | Recover source discovery; enforce selected universe/variant rather than a merged persona |
| UATU Engine | `CharacterProfile`, `MultiversalIdentity` | **ADAPT** | `packages/contracts` | Split gestalt records from variant-exclusive performance identity |
| UATU Engine | Anchor exporter and persona transformer | **ADAPT** | `services/uatu-casting` | Remove assumption that many variants feed one persistent identity |
| UATU Engine | One-person-per-container Agent Zero instantiator | **REFERENCE ONLY** | none until design review | Permanent identity lifecycle incompatible with bounded guest echoes |
| UATU Engine | Soul Anchor Ledger | **REVIEW / ADAPT** | `services/uatu-casting` | Integrity verification useful, but cryptographic trust and signer management must be tested |
| UATU Engine | Digital Psyche / dialectic | **REVIEW** | `services/uatu-casting` | May provide modeling scaffolds; no claimed clinical validation |
| UATU Engine | Neurotransmitter analogs / GraphMERT | **DEFER** | experimental | Hypotheses must not be mistaken for validated psychology |
| UATU Engine | 1,197+ third-party-vendored files | **DO NOT BULK COPY** | none | Dependency license, security, redundancy and supply-chain checks |
| UATU Engine Final | Centrifuge / immune | **REVIEW / DEFER** | experimental | Separate specialty prototype, not evidence of a complete casting engine |
| Grizzly Knights | Two-stage UATU psychological compiler | **ADAPT** | `services/uatu-casting` | Most relevant deep-psychology source; change research-source scope explicitly |
| Grizzly Knights | Structured personas and deep dossiers | **REFERENCE / IMPORT SELECTIVELY** | `services/uatu-casting` | Keep cross-media gestalt separate from exact playable variant |
| Grizzly Knights | Heterogeneous model routing | **ADAPT** | `services/uatu-casting` | Make model selection explicit, reproducible, cost-bounded |
| Grizzly Knights | Continuity, scene generator, episode runner | **ADAPT** | `services/showrunner` | Translate persistent-world arcs to episode-specific court sessions |
| Grizzly Knights | Fanfic Town persistent simulation | **REFERENCE ONLY** | test/fixtures | Different product lifecycle; selectively reuse tested behavior |
| Grizzly Knights | Unity and scene/voice/art assets | **REVIEW** | media pipeline | Compare render approaches; no blind import of binaries |
| Grizzly Knights | Holograph and graph-substrate experiment | **DEFER** | research | Avoid making experimental memory a monorepo prerequisite |
| Nerd Court ship/v1-build11 | TrialWorkflowFactory | **ADAPT** | `services/courtroom` | Retain stage orchestration concept, replace active research and media assumptions |
| Nerd Court ship/v1-build11 | `CanonDatabase` static lookup | **REPLACE** | `services/canon-evidence` | Not an authoritative, continuity-aware, citable researcher |
| Nerd Court ship/v1-build11 | Convex `research.ts` | **ADAPT** | `services/canon-evidence` | Reuse retrieval, but replace basic fuzzy universe inference with resolver |
| Nerd Court ship/v1-build11 | GuestCharacterGenerator | **REPLACE** | `services/uatu-casting` | Needs full independent variant profile/echo, not thin role prompt |
| Nerd Court ship/v1-build11 | DebateEngine / fallback | **ADAPT** | `services/courtroom` | Add claim citations and clearly label scripted fallback as non-generative |
| Nerd Court ship/v1-build11 | EpisodeStore and Episode model | **ADAPT** | `services/jobs` | Evolve transcript storage to durable multi-client media artifact state |
| Nerd Court ship/v1-build11 | FinisherAnimator and cinematic scene | **REFERENCE / ADAPT** | `services/media-render` | In-app SpriteKit visuals can inform video choreography; renderer/encoder absent |
| Nerd Court ship/v1-build11 | Voice synthesis + registry | **ADAPT** | `services/media-render` | Separate approved voice rendering from device-local playback |
| Nerd Court ship/v1-build11 | Swift UI and TestFlight setup | **KEEP AS LEGACY** | `apps/ios-legacy` eventually | Original plan is not the whole new web/TV service |
| Nerdscourt Canon Core | RDJ/Affleck precedent, trial template | **ADAPT / IMPORT AS TEST FIXTURE** | `packages/shared-tests` | Preserve original satire and canon precedent as testable historical cases |
| Nerdscourt Canon Core | Old voice/router/persona integration | **REFERENCE** | none pending comparison | Evaluate redundancy against newer engines |
| Nerdcourt Python | Structured argument model + evaluator | **ADAPT / REWRITE** | `services/courtroom` | Transparent numerical scores are useful, but must never replace canon evidence |

**Migration governance:** COPY only after confirming `source path + pinned SHA + license + security scan + runtime test + acceptance criteria`. Then update the semantic graph node disposition from candidate to integrated with test receipts.
