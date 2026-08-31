---
name: orchestration
description: "Default unless opted out. Native V2 balances Luna/Terra/Sol by role; Sol primary owns contracts, authorization, risk, and acceptance."
---

Load references/role-contracts.md, references/native-v2-lane.md, and
references/external-specialist-lane.md before delegation.

### Sol ownership

Sol owns intent, architecture/contracts, authorization, risk/rollback, integration, and acceptance.
`worker` owns a decision-complete coherent write phase; do not atomize multi-file or cross-repository
work. A primary-only `micro-edit` needs one inspected owned file, a settled atomic change, no writer
ambiguity, and one local non-browser check only when packet and review overhead exceed saved context.
Tool selection does not waive acceptance evidence or permit weakening acceptance.

For non-trivial work with an unknown runtime path, ownership, or caller flow, use evidence-only RECON:
`explorer` for one bounded trace and `deep_explorer` for cross-package/cross-repository, competing,
legacy-generated, or architecture-sensitive paths. Status answers, strict micro-edits, and decision-complete worker phases skip RECON only when location/runtime path and contract are known.

### Native V2 model routing

Choose one logical role, then pin its route:

| Role / class | Model | Effort |
|---|---|---|
| `explorer` | `gpt-5.6-luna` | `high` |
| `deep_explorer` | `gpt-5.6-terra` | `high` |
| `worker` mechanical fast-path | `gpt-5.6-luna` | `high` |
| `worker` normal | `gpt-5.6-terra` | `high` |
| `tester` | `gpt-5.6-luna` | `high` |
| `reviewer` normal | `gpt-5.6-sol` | `medium` |
| `reviewer` critical-risk | `gpt-5.6-sol` | `high` |

Specialized role presets are immutable Luna/Max carriers. Every mixed-lane spawn uses
`agent_type=default`, its resolved model/effort, and `fork_turns=none`; the packet carries
`logical_role` and `route_class`. Exact carrier/route acceptance is required; conflicts or fallback
block, omitted metadata is `unobservable`, and there is no silent fallback. Detailed worker predicates,
reviewer risk, browser/runtime QA, packets, corrections, and acceptance are in the loaded references.

Native V2 does not require app-task tools or legacy Terra/Sol companion roles; those are explicit compatibility paths. External specialists are opt-in, are not a sixth native role, have no production source ownership, and Sol must accept the artifact/evidence before issuing a native `worker` packet.
