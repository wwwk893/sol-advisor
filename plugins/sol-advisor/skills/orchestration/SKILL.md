---
name: orchestration
description: "Use by default for every new user request: answers, status, installation, commits/pushes, implementation, tests, review, audits, and routing. Keep simple, status-only, install-only, commit/push-only, and no-subagent requests in a direct primary-only path without spawning. Delegate engineering work through native V2 Luna Max with primary supervision. Compatibility lanes are explicit only. Opt out only when the user explicitly says not to use Sol Advisor or orchestration for this task."
---

# Sol Advisor Orchestration

Own intent, integration, and acceptance coordination. Load
[role-contracts.md](references/role-contracts.md), [native-v2-lane.md](references/native-v2-lane.md),
or explicit compatibility [luna-task-lane.md](references/luna-task-lane.md) on demand.

## Route

- **Default activation:** load this skill for every new request unless the user opts
  out of Sol Advisor/orchestration. Activation does not require a child: keep simple,
  status-only, install-only, commit/push-only, and no-subagent requests primary-only.
- **Native V2 (default delegation):** delegate useful engineering work to
  `deep_explorer`, `explorer`, `worker`, `tester`, or risk-gated `reviewer` via native
  `spawn_agent`, `list_agents`, `wait_agent`, `followup_task`, `send_message`, and
  `interrupt_agent`.
- **Compatibility:** App-task Luna and legacy Terra/Sol are explicit choices only;
  native V2 does not require project/thread tools or companion-role installation.

## Native state machine

`PREPARE → PREFLIGHT → SPAWN → MONITOR → INSPECT → CORRECT → VALIDATE → optional REVIEW → ACCEPT/STOP`

Spawn explicitly with `agent_type=<role>`, `model=gpt-5.6-luna`, `reasoning_effort=max`,
and `fork_turns=none`. Role availability and accepted Luna/max spawn are hard prerequisites.
Metadata conflict or fallback is a hard stop; missing model/effort/
priority is an `unobservable` warning when no conflict evidence exists. No silent fallback.

One execution plus at most two correction rounds is the default; continue with clear
progress or user direction. Three concurrent children is a soft suggestion; one writer
at a time is hard. Review only for material risk or user request. Tester is read-only
by default; a parent may assign bounded repair/test-only ownership, otherwise return a blocker.
Corrections use the same child.

Children preserve unrelated edits and do not commit, push, deploy, delete, upload,
mutate external services, or handle secrets unless explicitly authorized in scope.

## Acceptance and output

The primary inspects ownership and diff, then reruns the narrowest decisive acceptance subset
with local, non-browser checks; browser/runtime QA stays with the same tester. The primary
enters the browser only on explicit user request. Expand only when risk or impact warrants it.
Return `STATUS` (`complete|partial|blocked`), evidence, gaps, and residual risk.
