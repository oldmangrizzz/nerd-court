# GitHub Awesome #56 — tools relevant to Nerd Court

**Investigated:** 2026-10-30  
**Video:** [GitHub Trending Weekly #56](https://youtu.be/S8g5nwZN9as), uploaded 2026-10-30 by GitHub Awesome. We reviewed the description, chapters and complete auto-generated transcript, then checked the official GitHub repositories, README documentation and licenses of selected candidates.

**Status:** Research and shortlist only. **No external software has been installed or benchmarked in Nerd Court.** Exact upstream commit pins, typed target subsystem links, and unresolved restrictions are in [the supplemental candidate graph](external-candidates/2026-10-30-github-awesome-56.graph.json). The source-backed baseline remains **4,428 nodes / 4,650 edges**; the candidate graph is intentionally supplemental and does not silently revise those validated counts.

## Most immediately useful

### 1. Floorplan — architecture reverse-engineering and navigable map ([3:39](https://youtu.be/S8g5nwZN9as?t=219))

**Repository:** [haydenschmitty/floorplan](https://github.com/haydenschmitty/floorplan/tree/2287cc1a2bb4260ec7b8fd8dde45f40599e596b4)  
**License:** MIT.  
**Disposition: TEST ONLY.**

It scans source code, imports, endpoints, frontend requests and server routes across repos, with a browsable plain-English map and code health checks. It has a blueprint mode for unbuilt services, useful for representing planned Nerd Court components distinctly from verified source code.

**Direct win:** finish the most important incomplete layer of the current knowledge graph: observed imports, function calls and cross-repository runtime data flows. Feed evidence from an actual multi-repo Floorplan scan *back into* the version-controlled graph, rather than treating Floorplan's transient local output as the canonical architecture record.

**Limits:** The tool's stated code-language list does **not include Swift**, even though Nerd Court's advanced client is Swift/SpriteKit. Its Swift coverage and Swift-to-Convex traceability require an independent experiment. It normally stores its graph locally without committing it; no automatic import into our graph is demonstrated.

**Acceptance:** On pinned multi-repo workspaces, prove it can recover selected known Python/TypeScript paths, then inspect and validate Swift `ResearchNode` -> `CanonDatabase`, the separate Convex `runFullResearch`, and court voice/rendering boundaries. Every asserted call edge must have path+line evidence.

### 2. Kinetograph — programmatic video renderer ([8:44](https://youtu.be/S8g5nwZN9as?t=524))

**Repository:** [0xS4N4TG/kinetograph](https://github.com/0xS4N4TG/kinetograph/tree/7b0f4e69013e427cd2905c5ecd292fc0268a2224)  
**License:** PolyForm Small Business 1.0.0; commercial eligibility/redistribution review required.  
**Disposition: TEST ONLY.**

A TypeScript/Remotion-compatible composition pipeline using a Rust/wgpu/Skia compositor, audio support and FFmpeg. It can produce real video files and offers agent-facing QA tools including `still`, `strip`, `inspect`, `lint`, `render`, `audio_analyze`, `bench` and `snapshot`.

**Direct win:** bridge the gap from Nerd Court's existing in-app SpriteKit theatrical animation to an actual MP4 episode master. The original court visual design could be expressed as a deterministic storyboard/shot contract rendered to file. It should not be assumed that Swift SpriteKit code runs directly under Kinetograph.

**Limits:** Upstream calls it **beta v0.2.5** and lists incomplete features. Short-scene render times demonstrated on an Apple M4 are **not** benchmarks for 15–30-minute episodes with dynamic characters. No local performance test has been run. The PolyForm Small Business terms are **not** the MIT or Apache licenses often implied by the phrase "open source."

**Acceptance:** Render and decode a **30–90-second original** multi-shot courtroom proof with character entrances, subtitles, cutaways, dialogue audio, one stylized action beat, a shot continuity manifest, and frame/voice synchronization checks. Collect actual CPU/GPU time and output size. Preserve a separate path for asset/character generation.

## Valuable, but secondary or restricted

| Candidate | Video chapter | Potential use | Restriction / decision |
|---|---|---|---|
| [Pika H3 Flex](https://github.com/Pika-Labs/Pika-H3-Flex/tree/4bf8ea508891a432106e70f675d287c27f02306d) | [7:52](https://youtu.be/S8g5nwZN9as?t=472) | Reference-conditioned 5–15 s video shots with stereo audio | **LICENSE HOLD:** Model license explicitly excludes USA, EU, UK and South Korea; separate hosted API terms. Tested local generation uses H100-class resources, ~66–69 GiB GPU memory for 480p/5s and 211+ GB model components. Apache license applies to code, not model. |
| [Video to Game](https://github.com/lovisdotio/video-to-game/tree/d1a24fd8a47576ec4b3c36388b30deda0631def9) | [12:31](https://youtu.be/S8g5nwZN9as?t=751) | Video-as-visual-spec pipeline, palettes, camera/motion study, asset references | Makes a browser game, **not** a TV episode; depends on paid external asset generation. Reference only. |
| [Filmimic](https://github.com/DreamyLab30/Filmimic/tree/c8695dd65f74b42a4e8aca0b3740645506d47d24) | [14:19](https://youtu.be/S8g5nwZN9as?t=859) | Film-style color treatment for a possible Unreal rendering option | Unreal 5.8.3/Windows/DX12 tested; GPL-2.0-or-later and separate Unreal terms; Movie Render Queue not verified. Defer. |
| [Lever](https://github.com/github/lever/tree/f859d0aa2be96981157ee0480655c84877e3cd98) | [11:40](https://youtu.be/S8g5nwZN9as?t=700) | Measure-test-improve development loops and bounded Copilot workflows | Developer-process candidate; not a runtime dependency. Review. |
| [ub-mode](https://github.com/unclebob/ub-mode/tree/57a8bdd28e45ed41900ace0bafa2ff76dd9ed70f) | [0:36](https://youtu.be/S8g5nwZN9as?t=36) | Behavioral TDD, complexity and mutation-test discipline | Code ownership/license for this root skill not fully checked; evaluate companion tools before copying. |
| [SoMark OXR](https://github.com/SoMarkAI/OXR/tree/c1a1dcb312ee9f691404f127785510453c0d9350) | [1:33](https://youtu.be/S8g5nwZN9as?t=93) | Extract text, panels/layout and coordinates from documentary canon inputs | Custom Apache-based license with revenue/funding and hosted service restrictions; local GPU documentation specifies NVIDIA hardware. Optional. |
| [Strata](https://github.com/Niko1221/Strata/tree/870aedd9e1ebe1c91f94da93b59af17729f6c5c0) | [2:00](https://youtu.be/S8g5nwZN9as?t=120) | Local model inference/router for approved hardware | Current listed support is specific to modern AMD, NVIDIA, Intel and Apple configurations, not universal legacy AMD; optional and deferred. |

## Practical integration sequence

1. **Architectural proof:** Try Floorplan against the six pinned source repositories. Record a human-reviewable file/call/API trace; confirm or refute all inferred cross-repo edges.
2. **Video proof:** Separately trial Kinetograph to produce a *real, decodable* A/V MP4 from a manually curated non-copyrighted test scene; test independent production timing and memory use.
3. **Bridge proof:** Author a small, typed storyboard from the existing court pipeline and render it with the candidate video engine. Compare output with source-approved camera/character/voice specifications.
4. **Gate:** Keep technology decision as **TEST ONLY** until reproducible rendering, legal eligibility, and distribution constraints are checked. Do not import Pika H3 model weights or add them to production in an excluded territory without separately resolved licensing.
5. **Reevaluate:** Keep existing UATU identity and cast fidelity tests in scope; rendering success alone does not prove authentic characters or canon-based verdicts.

## Epistemic distinction

- **Verified from upstream files:** Repo existence, metadata, declared interfaces, README capability descriptions, license text and hardware requirements.
- **Upstream claims, not independently benchmarked:** Kinetograph throughput, Floorplan multi-repo mapping fidelity, Pika generation quality and any model/OCR benchmark scores.
- **Not built for Nerd Court:** Floorplan cross-repo integration, Kinetograph renderer, semantic source bridge into a playable episode, Pika adapter, or any finished 15–30-minute generated television episode.
