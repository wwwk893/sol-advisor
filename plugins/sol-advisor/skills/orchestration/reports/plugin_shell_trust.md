# Plugin shell trust report — Sol Advisor 0.7.0

Scope: every shipped `plugins/sol-advisor/scripts/*.sh` entrypoint. This is separate from the
Yao trust report, which is scoped only to `skills/orchestration` and is not package-wide shell
trust evidence.

The inventory is exact and machine-checked by `verify-coordination.sh`. Each file has a SHA-256
source hash, passed `sh -n`, and passed a local scan for network-capable commands/URLs. The report
also classifies file writes and side effects. The installer boundary is explicit: only the supplied
compatibility-agent target and allowlisted Terra/Sol files may be mutated; global config, cache,
Git, and external services are outside the boundary.

| Script | SHA-256 (source) | `sh -n` | Network scan | Side-effect classification |
| --- | --- | --- | --- | --- |
| `scripts/install-agents.sh` | `b15a3e1b3189107b8143577d2e389448d57cd08eb603a544f8616610fc35196a` | pass | pass; none | explicit compatibility-agent target only |
| `scripts/verify.sh` | `28628c57cbbe8697fd64d8f465a4f6b1c328d255ef77a64f79e77f91b8c89f82` | pass | pass; none | local checks and guarded temporary data |
| `scripts/verify-coordination.sh` | `aa166a7bc9ba6da7d2cc6c9bf2a68400b997af320e14b519ce3b9b87a092b574` | pass | pass; none | local fixture/report reads |
| `scripts/verify-external-specialist.sh` | `6152649f10a4d6ee48092ab7a67c68419799e08a0ab2a7beec1fca23391f2fc4` | pass | pass; none | local contract/fixture reads |
| `scripts/inspect-agent-runtime.sh` | `ed97bad2f43ee1e7bc4e4c5e9a6d1d1b8cb5d17dc4318727886afe88cd4c4eb4` | pass | pass; none | one guarded temporary match list |

This trust report is deterministic source evidence, not runtime enforcement, sandbox proof, or an
external approval. Hashes must be regenerated whenever a listed shell script changes.
