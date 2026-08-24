---
name: orchestration
description: "Use by default for every new user request: answers, status, installation, commits/pushes, implementation, tests, review, audits, and routing. Keep simple, status-only, install-only, and no-subagent requests primary-only. Prefer a scoped native V2 worker for authorized commit/push to reduce primary-context token use, reusing the implementation worker when available. Delegate engineering work through native V2 Luna Max with primary supervision. Compatibility lanes are explicit only. Opt out only when the user explicitly says not to use Sol Advisor or orchestration for this task."
---

# Sol Advisor Orchestration

Own intent, integration, and acceptance coordination. Load
[role-contracts.md](references/role-contracts.md), [native-v2-lane.md](references/native-v2-lane.md),
or explicit compatibility [luna-task-lane.md](references/luna-task-lane.md) on demand.

## Route

- **Default activation:** load this skill for every new request unless the user opts
  out of Sol Advisor/orchestration. Activation does not require a child: keep simple,
  status-only, install-only, and no-subagent requests primary-only.
- **Commit/push preference:** when the current request authorizes commit/push, prefer
  reusing the implementation `worker`; otherwise start one bounded `worker` with a compact
  exact-scope packet. Use the primary only when the user requests no subagent or as a
  disclosed safe fallback when delegation is unavailable and was not explicitly required.
  Git authorization does not imply Jira, deploy, force-push, or broader file authority.
- **Native V2 (default delegation):** delegate useful engineering work to one selected
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

One execution plus at most two correction rounds is the default; record a machine-readable
`correction_round: 0` on the initial packet and use `1` or `2` for corrections sent to the same child.
Continuing beyond two requires a recorded `continuation_reason`; record `user_direction` as the
quoted direction when present, otherwise `none`. Continue beyond two only for clear progress or
explicit user direction; never create a replacement child to reset the counter.
Three concurrent children is a soft suggestion; one writer at a time is hard. The worker is the
default product writer; a tester is read-only by default and may write only as an explicit bounded repair/test-only
exception with repair authorization, exact file ownership, a failed relevant check, and no active worker writer;
then it is the sole writer for that owned set; otherwise return a blocker. Review only for material risk or user request.

Behaviorally read-only `deep_explorer`, `explorer`, `reviewer`, and read-only `tester` runs must
capture actual model, effort, sandbox, and permission metadata, including a possible `danger-full-access`
profile. Record and compare worktree state before and after work; host metadata is not OS-enforced
read-only isolation. If mutation is observed, fail and invalidate the read-only result.

Children preserve unrelated edits and do not commit, push, deploy, delete, upload,
mutate external services, or handle secrets unless explicitly authorized in scope.

## Acceptance and output

The primary inspects ownership and diff, then reruns the narrowest decisive acceptance subset
with local, non-browser checks; browser/runtime QA stays with the same tester. The primary
enters the browser only on explicit user request. Expand only when risk or impact warrants it.
Return `STATUS` (`complete|partial|blocked`), evidence, gaps, and residual risk.
