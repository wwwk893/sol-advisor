# Native Luna V2 lane

This is the normative default workflow for Sol Advisor. Legacy Terra/Sol and app-task
paths are compatibility lanes, not this default. The native lane uses the host's native
`spawn_agent`, `list_agents`, `wait_agent`, `followup_task`, `send_message`, and
`interrupt_agent` semantics. It does not require `list_projects`, `create_thread`, or
other app-task tools, and it does not install or remove custom-agent TOMLs.

## Runtime contract

The available role names are `deep_explorer`, `explorer`, `worker`, `tester`, and
`reviewer`. The primary explicitly requests `gpt-5.6-luna` with `max` effort. Role
availability and spawn acceptance of that explicit route are hard prerequisites. If
public spawn or rollout metadata explicitly conflicts or shows a fallback, stop; if
accepted metadata omits model or effort, record an `unobservable` warning and continue
ordinary work when no conflict evidence exists. There is no silent fallback. `priority`
has the same warning semantics when omitted. The primary model and effort are
informational and are not a hard stop.

The primary uses one selected role from this set; choose the smallest role that fits the request.
Sol keeps intent, architecture/contracts, authorization, risk/rollback, irreversible scope,
option selection, integration, residual-risk acceptance, and final acceptance. Luna receives an
exact Sol-owned question for bounded evidence or a decision-complete execution packet. Judge
delegation at a coherent write phase: the related repository mutations needed for the next
independently acceptable candidate state. `worker` is the default for a decision-complete
repository write phase; do not atomize multi-file or cross-repository work into tiny steps.
If an execution decision is not settled, gather evidence only or return `blocked`; never delegate
the final choice.

`worker` is the default product writer. The tester is the only exception to product writes, and
only with explicit repair authorization, exact file ownership, a failed relevant check, and no
active worker writer; then the tester is the sole writer for that owned set. Read-only roles may
be run concurrently when their ownership does not overlap. In a shared worktree, never run two
writers at once. Three concurrent children is a suggested default ceiling, not a hard limit.

Tracked product tests, proxy/config changes, and dependency or lockfile changes stay in the
worker's coherent write phase. When an explorer has one exact evidence question, primary works on
a different decision dimension or performs only a bounded purposeful spot-check; it does not
independently exhaust the same search space while the explorer is active.

When Git work is authorized for a native worker, record the starting branch, base commit, and
`git status`; stage only explicitly authorized changed files (the exact owned file set); model
commit and push as independent authorization flags (they may be granted together); never
force-push or rewrite history. The primary accepts only after verifying remote SHA, tree, and
readback acceptance. Git permission does not imply Jira, deploy, or other external mutation.
Authorized Git or Jira closeout is a decision-complete transaction: read before write; name the
exact target and action; carry independent authorization flags; state order, stop conditions, and
rollback; and return post-write readback. The worker performs the whole authorized transaction;
primary does not drip-feed mechanical approval.

Behaviorally read-only `deep_explorer`, `explorer`, `reviewer`, and read-only `tester` runs must
capture actual model, effort, sandbox, and permission metadata, including a possible
`danger-full-access` profile. Record and compare worktree state before and after work; host
metadata is not OS-enforced read-only isolation. If a mutation is observed, fail and invalidate
the result.

## Lifecycle

### PREPARE

The primary resolves intent, architecture/contracts, authorization, risk/rollback,
irreversible scope, ownership, option selection, and acceptance evidence.
Choose the smallest role: explorers for questions, worker for settled implementation,
tester for focused runtime evidence, and reviewer only for a high-risk boundary or an
explicit user request. A tester does not change product code by default; its only bounded repair/test-only
exception requires explicit repair authorization, exact file ownership, a failed relevant check, and no active
worker writer; otherwise return a blocker.
A primary micro-edit may stay in the primary session only when it is one repository, one
already-inspected owned file, a genuinely atomic settled change, has no active writer or
overlapping/unclear dirty ownership, and needs at most one narrow local non-browser check, with
packet and review overhead exceeding saved context. Do not spawn an execution role until its packet is
decision-complete; an evidence-only role may investigate an exact unresolved Sol-owned question.
Unresolved or contradictory execution judgment returns to Sol. Current user scope or exact tool
choice may narrow project defaults; project rules cannot reopen an explicitly excluded path.

Browser/runtime QA routes to one tester end to end through durable `$chrome:control-chrome` with
the Chrome-family browser-client runtime. An exact current-turn user selection may override it;
generic “browser plugin” resolves to Chrome. The in-session `tab.playwright` API is allowed, but do
not substitute `$browser:control-in-app-browser`, Browser, BrowserMCP, Computer Use,
standalone Playwright or Playwright CLI, or another CLI.
If the resolved tool or required extension/client is unavailable, return the exact blocker; for the
default or generic Chrome route, point to Settings -> Computer use. Never silently fall back.
Tool selection does not waive repository-required acceptance evidence; if the selected route cannot
produce it, return the incompatibility to Sol instead of changing tools or weakening acceptance.
Before the first browser action, readiness must settle URL/environment, candidate state, free writer
slot, resolved browser tool and required extension/client (Chrome route plus extension when the
default or generic route resolves to Chrome),
server command/port/health/cleanup, credentials/test-data scope, and pre/post observable signals.
The worker owns tracked setup; tester owns reversible runtime prep, the resolved browser session,
server lifecycle, and evidence.

Build a compact packet from
[role-contracts.md](role-contracts.md). State `fork_turns: none`, exact owned files,
interfaces, constraints, verification commands, and a structured return. Do not copy
the entire conversation, prompt history, or full diff.

The spawn shape is:

```text
agent_type=<deep_explorer|explorer|worker|tester|reviewer>
model=gpt-5.6-luna
reasoning_effort=max
fork_turns=none
```

The compact task packet and reviewer return schema are defined in `role-contracts.md`.

### PREFLIGHT

Inspect the native tool's actual role surface and prepare the explicit route fields.
Require the exact role and an accepted spawn request with `model=gpt-5.6-luna`,
`reasoning_effort=max`, and `fork_turns=none`; stop if the role is unavailable or the
spawn rejects the request. If accepted public metadata or rollout evidence conflicts or
shows a fallback, stop; if fields are omitted, emit an `unobservable` warning rather
than blocking an ordinary task. Capture `priority` when exposed, otherwise warn. Confirm
the shared-worktree writer slot is free.

### SPAWN

Call `spawn_agent` with the selected `agent_type`, `model=gpt-5.6-luna`,
`reasoning_effort=max`, and `fork_turns=none`. This explicit route is intentional, not a
fallback. Do not use an app task, nested CLI, or legacy Terra/Sol role in this lane.

### MONITOR

Use `list_agents` for state and `wait_agent` for completion/evidence. Use `send_message`
for a factual progress request. Use `interrupt_agent` only for a user-requested stop,
safety boundary, or a clearly abandoned child. Do not impose a rigid short timeout;
waiting may be longer when the child is making progress.

### INSPECT

Read the handoff, then inspect the actual worktree, complete diff, changed-file scope,
and relevant generated/runtime artifacts in the primary session. Treat child claims as
untrusted until the primary verifies the actual artifacts. For tester-owned browser/runtime
QA, inspect the evidence and send gaps back to the same tester instead of reproducing the
browser session.

### CORRECT

If the result is partial or a check fails, issue a precise `followup_task` (or
`send_message`) to the same child with the failing evidence and required correction.
Record machine-readable `correction_round: 0` for the initial packet and `1` or `2` for
corrections. Beyond two requires a recorded `continuation_reason`; record `user_direction` as the
quoted direction when present, otherwise `none`. Continue beyond two only for clear progress or
explicit user direction. Never create a replacement child merely to reset the counter or dodge an
unresolved correction.

### VALIDATE

Rerun the narrowest decisive acceptance subset in the primary session with local, non-browser checks
and inspect behavior, not only exit status; browser/runtime QA remains
with the same tester end to end unless the user explicitly asks the primary to perform it.
Expand validation only when risk or impact warrants it; do not unconditionally repeat every
child check. Confirm no out-of-scope file changed, no unrelated user edit was reverted, and
no forbidden external mutation or secret handling occurred.

### REVIEW (optional)

For high-risk changes or an explicit review request, spawn `reviewer` with a fresh
`fork_turns: none` packet and require the reviewer return schema from `role-contracts.md`.
Capture actual model, effort, sandbox, and permission metadata for every behaviorally read-only
role; if the host reports `danger-full-access`, report that writable profile, compare exact
before/after state, and fail on mutation. Any mutation invalidates the result and requires a fresh
run. Ordinary low-risk tasks do not require this extra role.

### ACCEPT / STOP

Accept only when the objective, interfaces, ownership, runtime evidence, and acceptance
subset agree. If role availability, spawn acceptance, an explicit conflict/fallback,
ownership, or safety rule cannot be satisfied, stop and report the exact blocker. Missing
observable model/effort/`priority` fields after an accepted explicit request are warnings
when no conflict evidence exists, not automatic stops for ordinary work.

## Safety and external actions

Children preserve concurrent edits and remain within the packet. They may not commit,
push, deploy, delete, upload, mutate external services, or process keys/tokens/cookies
unless the user explicitly authorizes that action and the primary keeps the action in
scope. The primary performs authorized external mutations assigned to the primary and
verifies tester-owned authorized runtime actions through evidence. A child reporting
failure is followed up in place rather than silently rerouted.
