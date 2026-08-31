---
name: orchestration
description: "Default unless opted out. Native V2 balances Luna/Terra/Sol by role; Sol primary owns contracts, authorization, risk, and acceptance."
---

Load references/role-contracts.md, references/native-v2-lane.md, references/external-specialist-lane.md before delegation.

### Sol ownership

Sol primary owns intent, architecture/contracts, authorization, risk/rollback, integration, and acceptance. `worker` owns
decision-complete coherent write phases; don't atomize multi-file/cross-repo work. Primary-only `micro-edit`
requires one repository/file, one settled change, no active writer/dirty ownership ambiguity, and at most one narrow local
non-browser check when packet and review overhead exceed saved context. Commit/push authorization remains independent.

Non-trivial work with an unknown runtime path, ownership, or caller flow -> evidence-only RECON: `explorer` for one bounded trace; `deep_explorer` for cross-package/cross-repository, competing, legacy-generated, or architecture-sensitive paths. The primary frames the question without exhausting the same search. Status answers, strict micro-edits, and decision-complete worker phases skip RECON only when location/runtime path and contract are known.

### Native V2 model routing

Choose the smallest role first, then pin its model and effort. The balanced default matrix is:

| Role / class | Model | Effort |
|---|---|---|
| `explorer` | `gpt-5.6-luna` | `high` |
| `deep_explorer` | `gpt-5.6-terra` | `high` |
| `worker` mechanical fast-path | `gpt-5.6-luna` | `high` |
| `worker` normal | `gpt-5.6-terra` | `high` |
| `tester` | `gpt-5.6-luna` | `high` |
| `reviewer` normal | `gpt-5.6-sol` | `medium` |
| `reviewer` critical-risk | `gpt-5.6-sol` | `high` |

The worker mechanical fast-path is allowed only when all are true: exact owned files are known; at most two files are in the coherent write phase; the contract is fully settled; there is no cross-package/cross-repository flow; there is no dependency/lockfile change, tracked config migration, or generated/legacy reconciliation; and one focused local verification is sufficient. Otherwise use Terra High.

A reviewer is critical-risk when the review crosses production authentication/access-control or secrets boundaries, destructive or irreversible data/migration behavior, security-sensitive privilege boundaries, or another explicitly identified high-consequence residual-risk decision. Otherwise use Sol Medium. The reviewer never accepts residual risk for Sol.

Role availability and spawn acceptance of the exact selected route are hard prerequisites. Every request uses `fork_turns=none`; capture `priority` when observable. If public metadata conflicts or shows fallback, stop. If accepted metadata omits model/effort/priority without conflict evidence, record `unobservable`. There is no silent fallback to another model, effort, role, or provider.

Compatibility sentinel for the existing 0.6.8 core verifier: the previous uniform native route was `model=gpt-5.6-luna`, `reasoning_effort=max`, `fork_turns=none`. That uniform Luna/max route is forbidden for new native V2 spawns; the tokens remain here only so the older verifier can coexist with the new dedicated model-routing verifier.

Native tools are `spawn_agent`, `list_agents`, `wait_agent`, `followup_task`, `send_message`, and `interrupt_agent`. A failed or incomplete result goes back to the same child with a targeted correction; unresolved execution judgment returns `blocked` to Sol. Native V2 does not require app-task tools or the legacy Terra/Sol companion roles; those remain explicit compatibility lanes and are not the default. External specialists remain opt-in, are not a sixth native role, have no production source ownership, and Sol must inspect and accept the artifact/evidence before issuing a native `worker` packet.

### Browser/runtime QA

One `tester` owns browser/runtime QA end to end. Exact user-selected tools win and never silently fall back. Default/generic QA probes capability, records `selected route`, availability, and `fallback reason`, then uses `$chrome:control-chrome` with its Chrome extension and Chrome-family browser-client first; registered `chrome-devtools-mcp` with supported local stable Chrome in headless and isolated mode second; an already-installed runnable Playwright CLI as the last fallback; otherwise return a blocker with exact missing capabilities. Do not install/download or use an unselected tool. The in-session `tab.playwright` API is allowed. If the default Chrome extension is unavailable, record it, point to Settings -> Computer use, and continue down the default ladder. Human-visible auth/CAPTCHA, user-controlled MFA/biometric/physical presence, or an existing desktop-session requirement on headless returns to Sol for an explicit desktop Chrome reroute; never bypass or inspect stored auth state.

Readiness precedes browser action. Worker owns tracked setup; tester owns reversible runtime prep/evidence. The tester's bounded repair/test-only exception requires explicit repair authorization, exact file ownership, a failed relevant check, no active worker writer, and otherwise return a blocker.

### Acceptance boundary

Children preserve unrelated edits and stay inside exact ownership. Authorized Git work records starting branch, base commit, `git status`, the exact owned file set, and stages only explicitly authorized changed files. Commit, push, Jira, deploy, delete, upload, external mutation, and secret handling never imply one another.

Sol inspects the actual diff/evidence and reruns the narrowest decisive acceptance subset with local, non-browser checks. Browser/runtime QA remains with the same tester. Expand validation only when risk or impact warrants it. Same-agent corrections are preferred over spawning replacements merely to reset context or counters.
