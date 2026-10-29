# Draft v0 contracts

These are proposed schemas to enable the **first real integration boundary** between UATU casting and Nerd Court production. They are **not yet integrated into runtime** and must not be used to claim working output.

| Schema | Essential guard |
|---|---|
| `entity-reference.schema.json` | Real performer, historical figure, fictional individual and portrayal remain distinct typed entities |
| `evidence-claim.schema.json` | Observed canon/historical facts, interpretation, psychological inference and made-up show events cannot masquerade as each other |
| `echo-snapshot.schema.json` | One variant and one episode per echo; retention is explicit, underlying source canon immutable |
| `cast-manifest.schema.json` | Versioned cast, echo, voice, visuals and evidence before courtroom performance begins |
| `episode-job.schema.json` | Durable production states; `published` requires a verified video-master artifact |

These are **JSON Schema Draft 2020-12 proposals**. Git syntax validity is not equivalent to schema evaluation: before generating binding code, run a standards-compliant schema checker and positive/negative fixtures; adapt the `$id` naming and inter-schema references once the runtime packaging choice is fixed.

Decisions still open: archival retention periods, real-world participant rights controls, actor/role portrayal exceptions, staff cast memory scopes, auth model, voice provider policy, media container/codecs, idempotency uniqueness and error handling for partial productions.

The `architecture/knowledge-graph` documents contain the dependency graph, migration order, original source evidence, blockers and acceptance gates. Don't copy upstream code before resolving the relevant gate.