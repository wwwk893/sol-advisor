---
name: orchestration
description: "Use by default unless opted out. Keep simple/status/install/no-subagent work primary-only. Sol owns intent, architecture, risk, integration, and acceptance; Luna Max gets bounded questions or decision-complete coherent write phases. Compatibility is explicit."
---

Before spawning, load [role contracts](references/role-contracts.md) and [native lane](references/native-v2-lane.md).

- **Cognitive budget:** Sol owns intent, contracts, authorization, risk, integration, acceptance.
  Judge each coherent write phase; `worker` is default for decision-complete writes. Never atomize
  multi-file or cross-repository work. A primary-only micro-edit requires packet and review overhead
  exceeding saved context plus one repository, one inspected owned file, atomic settled change,
  no active/unclear dirty ownership, one narrow local non-browser check. Luna gets an exact
  evidence question or settled packet; unresolved execution judgment is `blocked`.
- **Native V2:** choose one `deep_explorer`, `explorer`, `worker`, `tester`, or `reviewer` via
  `spawn_agent`, `list_agents`, `wait_agent`, `followup_task`, `send_message`, and `interrupt_agent`;
  keep one writer. Request `agent_type=<role>`, `model=gpt-5.6-luna`, `reasoning_effort=max`,
  `fork_turns=none`; role availability/accepted spawn are hard prerequisites; no silent fallback.
  Missing model/effort/priority is `unobservable`; correct twice max with the same child.
- **Browser/runtime QA:** one tester uses durable/default `$chrome:control-chrome` with its Chrome-family
  browser-client. Exact later user selection may override it; generic “browser plugin” resolves to Chrome.
  In-session `tab.playwright` is allowed; do not substitute BrowserMCP, Computer Use, standalone
  Playwright, or Playwright CLI. If the resolved browser tool/client is unavailable, return the exact
  blocker and never silently fall back. Default/generic Chrome requires `$chrome:control-chrome` with
  its Chrome extension and Settings -> Computer use. Tool selection does not waive evidence;
  incompatibility returns to Sol, not weakening acceptance.
- **Commit/push:** authorized worker transaction reads before write, names exact targets/actions, carries
  independent flags, stop/rollback, and readback; Git permission does not imply Jira/deploy. Native V2
  does not require companion roles; app-task Luna and legacy Terra/Sol are explicit compatibility paths.

## Acceptance

Readiness is required before the tester's first browser action. Worker owns tracked setup; tester owns
reversible runtime/server/prep for the resolved browser tool/client (Chrome prep when Chrome resolves)
and evidence. Primary inspects the same tester's browser/runtime QA evidence and reruns the narrowest decisive acceptance subset
with local, non-browser checks, expanding when risk or impact warrants it.
