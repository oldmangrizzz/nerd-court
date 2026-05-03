# Handoff — build #11

## Done
- Delta retired; Ollama Cloud (ollama.com) is sole LLM path
- F5-TTS voice IDs aligned iOS↔server (jason_todd, matt_murdock, jerry_springer, deadpool_nph)
- Speech bubbles wired (TrialCoordinator → CourtroomScene.showSpeechBubble)
- VoiceSynthesisClient appends /v1/synthesize path
- Convex prod deployed (notable-kookabura-259)
- WG self-healing watchdog on Mac (egress 99.9.128.67)
- Archive + export + altool upload — UPLOAD SUCCEEDED
- Build #11 reached VALID in ASC, attached to Internal Testers group via REST

## Open
- F5-TTS voice refs lost on Cloud Run cold start (needs startup-replay)
- iOS XCTest regression hangs (declared environmental, deferred)
