# Nerd Court / UATU — Source-Backed Knowledge Graph (v1)

**Date:** 2026-10-28  
**Status:** Architecture reconnaissance and source inventory **complete for the six pinned repositories**; semantic dependency mapping is **reviewed but not a complete call graph**. No runtime or integration build is certified here.  
**Destination:** Existing `oldmangrizzz/nerd-court` repository, on a **non-production feature branch** derived from `ship/v1-build11`.

## What this package actually contains

This is a **joined, typed, auditable graph**, not a single inspirational flowchart:

| Layer | Materialized source | Coverage |
|---|---|---|
| Original tracked files | `sources/*.inventory.json` | **3,926 file paths**, blob SHAs, sizes and simple copy-risk flags; six repository heads pinned |
| Repository file/folder graph | `file-graphs/*.graph.json` | 3,926 file nodes, 340 directory nodes, 6 repository nodes, **4,266 containment edges** |
| Reviewed semantic graph | `semantic-graph.v1.json` | **162 nodes** and **295 typed relations**; 89 selected source modules, 34 proposed subsystems, 12 user requirements, 10 proposed acceptance tests and 11 risks |
| Verified join | `semantic-file-bridges.v1.json` | **89 exact file-reference edges** from the reviewed modules to the pinned source trees |
| Architectural decisions | `UNIFIED-ARCHITECTURE.md` and `MIGRATION-LEDGER.md` | What to reuse, adapt, quarantine, reject, test or build |
| Readable overview | `overview.mmd` | Mermaid process map for editors and non-developers |

**Combined graph (deduplicated by stable node IDs): 4,428 nodes and 4,650 edges.**

The file-level graph proves *where tracked files are*, not *what they execute*. Semantic edges may be **observed in source**, **proposed dependencies**, or **candidate reuse**; the type and reason field explain which. Runtime edges and function-level imports/calls are a separate **not-yet-completed** audit.

## Six pinned source repositories

| Repository | Pinned commit | Tracked files | Role and caveats |
|---|---|---:|---|
| [uatu-engine](https://github.com/oldmangrizzz/uatu-engine/tree/efeb4be539d0d22260c6c8bec97344bfa9e74504) | `efeb4be` | 1,396 | Genesis/Agent Zero, persona export, persistent identity design; substantial vendored Agent Zero tree |
| [uatu-engine-final](https://github.com/oldmangrizzz/uatu-engine-final/tree/9a67e62c411accd3a3c6d3374ca84dffac4a2b01) | `9a67e62` | 9 | Separate Centrifuge/immune state-vector prototype; name “final” does not prove production readiness |
| [grizzly-knights](https://github.com/oldmangrizzz/grizzly-knights/tree/78c32e607d7a726edd6d51f8f998980fb9c6f562) | `78c32e6` | 2,265 | UATU deeper compiler, psychological/personality files, multi-model world, scripts, sound, assets, continuity and experimental memory |
| [nerd-court, ship/v1-build11](https://github.com/oldmangrizzz/nerd-court/tree/b6b19b52045b8a641ac6d34c4045c7ded40943b7) | `b6b19b5` | 165 | Advanced SwiftUI/SpriteKit/Convex court, in-app audio and animation, debate workflow, fallbacks, tests |
| [nerdcourt](https://github.com/oldmangrizzz/nerdcourt/tree/3886276aaab72c1d38df475bc8591bc088cf5aa9) | `3886276` | 12 | Small transparent case-scoring/evaluation toolkit |
| [nerdscourt-canon-core](https://github.com/oldmangrizzz/nerdscourt-canon-core/tree/30564853301258bf534a291b3decbcd410729a98) | `3056485` | 79 | Historical case records, trial templates, persona and voice/model-routing experiments |

**Note:** The advanced court branch is *not* the repository’s older default `master`; pin it explicitly when comparing or migrating.

## How to read the graph

- A `repo:<name>` node represents a pinned source tree.
- A `dir:<name>:<path>` node is a tracked directory; `file:<name>:<path>` is a tracked file; `contains` is physical source-tree containment only.
- Source-facing semantic nodes (e.g. `nc:research` or `g:compiler`) have a pinned source URL and `file-present-not-runtime-verified` status.
- `t:*` targets describe proposed unified architecture. None is marked implemented.
- `q:*` are user-stated product requirements; `risk:*` unresolved engineering risks; `test:*` acceptance tests not yet executed.
- `candidate-for` means possible reuse, **not a running integration**. `depends-on` is proposed architecture, **not observed code wiring**.
- `backed-by-source-file` in the bridge file is an exact path/hash match, **not runtime verification**.

To reconstruct a combined graph, union all `nodes` from the six file graphs with semantic `nodes`, deduplicate by `id`, and concatenate `edges` from those files plus the bridge. Every edge endpoint should resolve to a node, and every selected semantic module must have precisely one exact source-file bridge. No software installation or graph database is needed to inspect the JSON.

## The requested television product (not to be confused with the old iOS plan)

The **viewer commissions a finished television episode** from a grievance. UATU must research and select specific fictional variants and real/historical performer identities, construct distinct bounded performance echoes, voice/visual casting instructions and cited claims. Nerd Court must create a trial, perform character-faithful competing arguments, render animation and sound, and publish a **watchable 15–30-minute** episode for web, mobile and TV. Finisher sequences are contingent on the story/verdict. Fast generation is a product target requiring real benchmarks, **not an observed capability**.

The archetype **gestalt** is a *reference*, not the performed character: exact variant, continuity, era and portrayal are independent. An episode’s invented event never silently updates source canon. Echo state can be kept for approved reuse, otherwise it is bounded by the episode.

## Main cross-repository contradictions discovered

1. [Old UATU README](https://github.com/oldmangrizzz/uatu-engine/blob/efeb4be539d0d22260c6c8bec97344bfa9e74504/README.md) declares **one person / one container / one mind** and persistent memory. Show guests require **per-case temporary echoes** with deliberate optional reuse.
2. [UATU `CharacterProfile`](https://github.com/oldmangrizzz/uatu-engine/blob/efeb4be539d0d22260c6c8bec97344bfa9e74504/uatu_genesis_engine/models/__init__.py) has distinct `MultiversalIdentity` entries, but the [anchor export](https://github.com/oldmangrizzz/uatu-engine/blob/efeb4be539d0d22260c6c8bec97344bfa9e74504/uatu_genesis_engine/orchestrator.py) retains a combined archetype under one primary persona. **Variant-exclusive compilation remains to be built.**
3. [Grizzly Knights UATU compiler](https://github.com/oldmangrizzz/grizzly-knights/blob/78c32e607d7a726edd6d51f8f998980fb9c6f562/engine/uatu_compiler.py) includes explicit **“full published canon, not adaptations”** research instructions. The user’s stated *gestalt across portrayals* is broader. Preserve the present compiler as historical evidence; resolve scope in the new schema rather than silently changing it.
4. [Swift `ResearchNode`](https://github.com/oldmangrizzz/nerd-court/blob/b6b19b52045b8a641ac6d34c4045c7ded40943b7/Sources/Pipeline/TrialNodes.swift) calls local `CanonDatabase.research`; a [distinct Convex external research action](https://github.com/oldmangrizzz/nerd-court/blob/b6b19b52045b8a641ac6d34c4045c7ded40943b7/convex/research.ts) exists. That does not prove external evidence reaches the active Swift trial node.
5. [Nerd Court `Episode`](https://github.com/oldmangrizzz/nerd-court/blob/b6b19b52045b8a641ac6d34c4045c7ded40943b7/Sources/Models/Episode.swift) is a transcript/verdict data object. [SpriteKit cinematic code](https://github.com/oldmangrizzz/nerd-court/blob/b6b19b52045b8a641ac6d34c4045c7ded40943b7/Sources/Animation/CinematicEngine.swift) is **in-app playback/effects**, not proof of a finished encoded video master.
6. Legacy scoring in [`nerdcourt/evaluator.py`](https://github.com/oldmangrizzz/nerdcourt/blob/3886276aaab72c1d38df475bc8591bc088cf5aa9/nerdcourt/evaluator.py) uses weighted argument scores and an optional bias. Do not let the score substitute for independently sourced canon truth.
7. The original blueprint says **iOS/TestFlight**; the current requirement is **web/TV/mobile on-demand television**. The old app is useful as a design/code source, not the entire target product.

## Safety of the consolidation

**No history was rewritten. No production app was changed.** This graph resides on a feature branch. Existing originals remain independent, pinned source records.

Do not copy entire trees blindly. Original sources include vendored frameworks, media binaries, potential credential-bearing or environment files, historical logs and third-party components. **Path inventories contain filenames and blob metadata only; they do not copy file contents.** Every prospective copied module needs source-license, secret-scan, data-provenance, variant-scope, tests and dependency review.

The next step is a **call/import/runtime data-flow audit** on the candidate modules, followed by small contract-first migrations with red-green-refactor tests. A successful graph build is not a successful episode production.

See [unified architecture](UNIFIED-ARCHITECTURE.md), [migration ledger](MIGRATION-LEDGER.md), and [gaps and acceptance tests](GAPS-AND-GATES.md).
