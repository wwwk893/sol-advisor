---
name: orchestration
description: "Use by default unless opted out. Native Luna V2 delegates bounded work; Sol owns contracts, authorization, risk, and acceptance."
---

Load references/role-contracts.md, references/native-v2-lane.md, and references/external-specialist-lane.md before delegation.

### Sol ownership

Sol owns intent, architecture/contracts, authorization, risk/rollback, integration, and acceptance.
`worker` defaults to a decision-complete coherent write phase; do not atomize multi-file/cross-repository work.
Primary-only `micro-edit`: one repository/file, one settled change, no active writer/dirty ownership ambiguity,
one narrow local non-browser check when packet and review overhead exceeds saved context.
Commit/push use independent authorization flags.

### Native V2

Choose the smallest role: `deep_explorer`, `explorer`, `worker`, `tester`, or `reviewer`. Native tools are
`spawn_agent`, `list_agents`, `wait_agent`, `followup_task`, `send_message`, `interrupt_agent`;
native V2 does not require app-task tools or legacy Terra/Sol compatibility lanes. Request:

```text
agent_type=<deep_explorer|explorer|worker|tester|reviewer>
model=gpt-5.6-luna
reasoning_effort=max
fork_turns=none
```

Role availability and accepted routing are hard prerequisites: no silent fallback; missing model/effort/priority is
`unobservable` absent conflict. Correct failures with the same child; unresolved execution judgment is `blocked`.
External specialists are opt-in, not a sixth native role. Sol owns exact provider/model, isolation, and acceptance
boundary; no production source ownership. Sol must inspect the artifact/evidence and accept it before issuing a Luna `worker` packet.

### Browser/runtime QA

One `tester` owns browser/runtime QA; the same tester supplies acceptance evidence.
An exact user-selected tool wins, is preflighted alone, and must never silently fall back. Default/generic
QA probes capability, records `selected route`, availability, and fallback reason, then uses:
`$chrome:control-chrome` with Chrome extension and Chrome-family browser-client (desktop preferred);
registered `chrome-devtools-mcp` with supported stable Chrome, headless and isolated; already-installed
runnable Playwright CLI as the last fallback; or block with exact missing capabilities. Do not
install/download browser tools or use an unselected tool. Detailed readiness/auth/escalation mechanics
are in the references. Tool selection does not waive repository-required acceptance evidence or justify weakening acceptance.

### Acceptance boundary

Readiness precedes the first browser action. Worker owns tracked setup; tester owns reversible runtime prep/evidence.
Sol inspects the same tester's evidence and reruns the narrowest decisive acceptance subset with local, non-browser checks,
expanding when risk or impact warrants it.
