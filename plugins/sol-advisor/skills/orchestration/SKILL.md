---
name: orchestration
description: "Use by default unless opted out. Keep simple/status/install/no-subagent work primary-only. Sol owns intent, architecture, risk, integration, and acceptance; Luna Max gets bounded questions or decision-complete execution. Compatibility is explicit."
---

# Sol Advisor Orchestration

Sol decides; Luna gathers evidence or executes settled work. Before spawning,
load normative [role contracts](references/role-contracts.md) and the
[native lane](references/native-v2-lane.md).

## Route

- **Default:** load unless the user opts out; activation does not require a child.
- **Cognitive budget:** Sol owns intent, architecture/contracts, authorization, risk,
  secrets, option selection, integration, and acceptance. Luna gets an exact Sol-owned evidence
  question or settled execution packet; unresolved execution judgment is `blocked`. Delegate only
  when savings exceed packet and review overhead.
- **Native V2:** choose one role from
  `deep_explorer`, `explorer`, `worker`, `tester`, or risk-gated `reviewer` via native
  `spawn_agent`, `list_agents`, `wait_agent`, `followup_task`, `send_message`, and
  `interrupt_agent`.
- **Commit/push:** when authorized, use a bounded `worker`; Git permission does not imply
  Jira, deploy, force-push, or broader authority.
- **Compatibility:** App-task Luna and legacy Terra/Sol are explicit choices only;
  native V2 does not require companion roles. Load the
  [app-task contract](references/luna-task-lane.md) only when explicitly selected.

## Native state machine

`PREPARE → PREFLIGHT → SPAWN → MONITOR → INSPECT → CORRECT → VALIDATE → optional REVIEW → ACCEPT/STOP`

Spawn explicitly with `agent_type=<role>`, `model=gpt-5.6-luna`, `reasoning_effort=max`,
and `fork_turns=none`. Role availability and accepted Luna/max spawn are hard prerequisites.
Conflict or fallback is a hard stop; missing model/effort/priority is `unobservable`, never
silent fallback. Use at most two corrections to the same child. Keep one writer.

Read-only roles capture actual model, effort, sandbox, and permission metadata and compare
state before and after because host metadata is not OS-enforced isolation. Mutation
invalidates the result. Browser/runtime QA uses the same tester and
`$browser:control-in-app-browser` browser-client; its `tab.playwright` is allowed, but
standalone Playwright CLI requires an explicit request; never silently fall back.

Children preserve unrelated edits and do not commit, push, deploy, delete, upload,
mutate external services, or handle secrets unless explicitly authorized in scope.

## Acceptance and output

The primary inspects ownership and diff, reruns the narrowest decisive acceptance subset with
local, non-browser checks, and expands only when risk or impact warrants it. It inspects the
same tester's browser/runtime QA evidence instead of repeating that work.
Return `STATUS` (`complete|partial|blocked`), evidence, gaps, and residual risk.
