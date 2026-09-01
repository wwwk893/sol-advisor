---
name: orchestration
description: "Sol Advisor 0.7.0 native Luna V2 routing with Sol-owned contracts, scope locks, and terminal barriers."
---

Load references/role-contracts.md, references/native-v2-lane.md, references/external-specialist-lane.md. scripts/evaluate_coordination.py; evals/coordination_cases.json.

Sol owns contracts, authorization, risk/rollback, acceptance; worker owns coherent write phase; decision-complete. Never atomize cross-repository. Primary-only `micro-edit`: one repository, one already-inspected owned file, genuinely atomic settled change, no active writer/overlap/unclear dirty ownership, at most one narrow local non-browser check; packet and review overhead exceeds saved context. unknown runtime path, ownership, or caller flow => evidence-only RECON: `explorer` for one bounded trace;
`deep_explorer` for cross-package/cross-repository or architecture-sensitive paths. Status answers, strict micro-edits, and decision-complete worker phases skip RECON only when location/runtime path and contract are known.

Native roles: `deep_explorer`, `explorer`, `worker`, `tester`, `reviewer`; tools: `spawn_agent`, `list_agents`, `wait_agent`,
`followup_task`, `send_message`, `interrupt_agent`. Does not require app-task tools or Terra/Sol compatibility.
Use `model=gpt-5.6-luna`, `reasoning_effort=max`, `fork_turns=none`. hard prerequisites; no silent fallback. Missing
model/effort/priority: `unobservable`; correct failures with same child; unresolved=`blocked`. External specialists
are not a sixth native role; no production source ownership; accept it before issuing a Luna `worker` packet.

Coordination: active-child ownership ledger for nonterminal scopes; do not duplicate/take over; correct same child.
Terminal coordination barrier waits acceptance-relevant predecessors before dependent/ACCEPT; inspect handoff/artifacts;
failed/blocked/interrupted need disposition; missing evidence cannot waive. Prefer long `wait_agent`; `list_agents` state;
silence is not abandonment; timeout-only waits emit no user-facing status/chatter. Reuse fresh evidence if scope/base/ownership/
config-runtime/contracts unchanged; drift/contradiction/unknown path invalidates/recon. Worker owns tracked tests/config/dependencies;
tester owns browser/runtime QA; after barrier Sol runs the narrowest decisive acceptance subset with local, non-browser checks
when risk or impact warrants it.

Tester owns browser/runtime QA; never silently fall back. `selected route`, `availability`, `fallback reason`:
`$chrome:control-chrome` Chrome-family browser-client; `chrome-devtools-mcp` headless/isolated; already-installed Playwright CLI
last fallback; block missing capabilities. Tool selection does not waive acceptance evidence or justify weakening acceptance. Sol inspects same tester evidence.
