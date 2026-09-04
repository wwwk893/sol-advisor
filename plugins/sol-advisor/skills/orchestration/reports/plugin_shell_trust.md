# Plugin shell trust report — Sol Advisor 0.7.1

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
| `scripts/verify.sh` | `413817c83284f72f4dfdbeb33cca6c57a60da973e95c26ba7d7fd0bd8e7d4682` | pass | pass; none | local checks and guarded temporary data |
| `scripts/verify-coordination.sh` | `bab8ccd91f3f430ac27e5e83dd9a7e54b265db69e24e3fee0b380ad81c4871ee` | pass | pass; none | local fixture/report reads |
| `scripts/verify-external-specialist.sh` | `8730ec851e0617785fa8de5f806367f9abd36f3eb46db69ba00415c332cadcbc` | pass | pass; none | local contract/fixture reads |
| `scripts/verify-model-routing.sh` | `c3c0abbe94a6815e8d5344c152e1a0caa574640c29677eab46d85d6d04ddf3a9` | pass | pass; none | local routing contract/fixture reads |
| `scripts/inspect-agent-runtime.sh` | `28a3c6f3c158a23f5596becf3a525bcd5beb9db9e67d529355ebdc3e3069e3c8` | pass | pass; none | one guarded temporary match list |

This trust report is deterministic source evidence, not runtime enforcement, sandbox proof, or an
external approval. Hashes must be regenerated whenever a listed shell script changes.
