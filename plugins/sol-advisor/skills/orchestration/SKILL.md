---
name: orchestration
description: "Sol Advisor 0.7.1 mixed Sol routing with Sol-owned contracts, latency guardrails, scope locks, and terminal barriers."
---

Load references/role-contracts.md and references/native-v2-lane.md for native delegation. Load references/external-specialist-lane.md only when that lane is admitted. For coordination evaluation, load scripts/evaluate_coordination.py and evals/coordination_cases.json.

Sol owns contracts, authorization, risk/rollback, acceptance; worker owns the decision-complete coherent write phase. Never atomize cross-repository. Primary-only `micro-edit`: one repository, one already-inspected owned file, genuinely atomic settled change, no active writer/overlap/unclear dirty ownership, at most one narrow local non-browser check; packet and review overhead exceeds saved context. unknown runtime path, ownership, or caller flow => evidence-only RECON: `explorer` for one bounded trace;
`deep_explorer` for cross-package/cross-repository or architecture-sensitive paths. Status answers, strict micro-edits, and decision-complete worker phases skip RECON only when location/runtime path and contract are known.

Native roles: `deep_explorer`, `explorer`, `worker`, `tester`, `reviewer`; tools: `spawn_agent`, `list_agents`, `wait_agent`,
`followup_task`, `send_message`, `interrupt_agent`. Native routes are exact hard prerequisites and use `fork_turns=none`; no silent fallback.
Exact matrix: `explorer=default/gpt-5.6-sol/low/normal`; `deep_explorer=default/gpt-5.6-sol/medium/normal`;
`worker=default/gpt-5.6-sol/medium/normal`; `reviewer.normal=default/gpt-5.6-sol/medium/normal`;
`reviewer.critical-risk=default/gpt-5.6-sol/high/critical-risk`; `tester=tester/gpt-5.6-luna/max/normal`.
Spawn syntax is `agent_type=default` for Sol routes and `agent_type=tester` for tester; packet `logical_role`/`route_class` are request intent, not observed facts. Absent host observations are `unobservable`.
Sol routes never request fast mode or priority service tier; explicit `fast_mode=true` or `service_tier=priority` blocks as a route conflict.
Missing model/effort/fast/service-tier metadata is `unobservable`, not proof it is disabled. Tester retains priority observability only when unavoidable.
An exact Luna worker/explorer request is an explicit compatibility-route override and an activation fixture, not evidence of the default route.
External specialists are not a sixth native role; no production source ownership; accept an admitted artifact before issuing a native `worker` packet.
The native lane does not require app-task tools or Terra/Sol compatibility lanes; those are explicit opt-ins.

Coordination follows the references: active-child ownership ledger, one writer, do not duplicate, terminal barrier, same child correction, and evidence freshness.
Worker owns tracked tests/config/dependencies; tester owns browser/runtime QA. After the barrier Sol runs the narrowest decisive acceptance subset
with local, non-browser checks when risk or impact warrants it.

Latency: send the worker one whole coherent implementation/check/return packet, never drip-fed mechanical follow-ups. Send one
batched tester acceptance packet only after the final candidate; rerun the same tester only for code/config drift or a precise evidence gap,
never for identical accepted checks. Reviewer is high-risk or explicit only, after the final candidate, with at most one logical reviewer
per candidate; targeted same-child corrections are not replacements. Do not claim speed improvement: A/B latency/token/service-tier remains missing evidence.
The coordination evaluator enforces these worker, tester, and reviewer state/action gates.

Tester owns browser/runtime QA; never silently fall back. `selected route`, `availability`, `fallback reason`:
`$chrome:control-chrome` Chrome-family browser-client; `chrome-devtools-mcp` headless/isolated; already-installed Playwright CLI
last fallback; block missing capabilities. Tool selection does not waive acceptance evidence or justify weakening acceptance. Sol inspects same tester evidence.
