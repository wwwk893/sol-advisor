---
name: orchestration
description: "Default unless opted out. Native Luna V2 delegates bounded work; Sol owns contracts, authorization, risk/acceptance."
---

Load references/role-contracts.md, references/native-v2-lane.md, references/external-specialist-lane.md before delegation.

### Sol ownership

Sol owns intent, architecture/contracts, authorization, risk/rollback, integration, acceptance. `worker` owns
decision-complete coherent write phase; don't atomize multi-file/cross-repo work. Primary-only `micro-edit`
requires one repository/file, one settled change, no active writer/dirty ownership ambiguity; one narrow local
non-browser check if packet and review overhead exceed saved context.
Commit/push independent.

Non-trivial work with an unknown runtime path, ownership, or caller flow -> evidence-only RECON: `explorer` for one bounded trace; `deep_explorer` for cross-package/cross-repository, competing, legacy-generated, or architecture-sensitive paths. Status answers, strict micro-edits, and decision-complete worker phases skip RECON only when location/runtime path and contract are known.

### Native V2

Choose smallest role: `deep_explorer`, `explorer`, `worker`, `tester`, or `reviewer`. Native tools: `spawn_agent`,
`list_agents`, `wait_agent`, `followup_task`, `send_message`, `interrupt_agent`. Native V2 does not require app-task
tools or legacy Terra/Sol compatibility lanes. Request:

```text
agent_type=<deep_explorer|explorer|worker|tester|reviewer>
model=gpt-5.6-luna
reasoning_effort=max
fork_turns=none
```

Role availability/accepted routing are hard prerequisites; no silent fallback. Missing model/effort/priority:
`unobservable` absent conflict; correct failures with same child; unresolved execution: `blocked`.
External specialists are opt-in, not a sixth native role: no production source ownership. Sol must inspect artifact/evidence and accept it before issuing a Luna `worker` packet.

### Browser/runtime QA

One `tester` owns browser/runtime QA; same tester owns evidence. Exact user-selected tools win; never silently fall back.
Default/generic QA probes capability, records `selected route`, availability, `fallback reason`; use `$chrome:control-chrome`
with Chrome extension/Chrome-family browser-client, registered `chrome-devtools-mcp` with headless/isolated Chrome, or
already-installed Playwright CLI last fallback; block with exact missing capabilities. Do not install/download
or use unselected tools. Readiness/auth/escalation mechanics are in references. Tool selection does not waive required acceptance evidence or
justify weakening acceptance.

### Acceptance boundary

Readiness precedes browser action. Worker owns tracked setup; tester owns reversible runtime prep/evidence. Sol inspects same tester evidence
and reruns the narrowest decisive acceptance subset with local, non-browser checks, expanding when risk or impact warrants it.
