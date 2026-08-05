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

`worker` is the only role allowed to write product files for a delegated implementation
and only inside its owned set. Read-only roles may be run concurrently when their
ownership does not overlap. In a shared worktree, never run two writers at once. Three
concurrent children is a suggested default ceiling, not a hard limit.

## Lifecycle

### PREPARE

The primary resolves intent, architecture, risk, ownership, and acceptance evidence.
Choose the smallest role: explorers for questions, worker for settled implementation,
tester for focused runtime evidence, and reviewer only for a high-risk boundary or an
explicit user request. A tester does not change product code by default; the parent may
assign a bounded repair/test-only change with exact ownership; otherwise return a blocker.
A small or tightly coupled change may stay in the primary session.

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
untrusted until the primary reproduces the evidence.

### CORRECT

If the result is partial or a check fails, issue a precise `followup_task` (or
`send_message`) to the same child with the failing evidence and required correction.
The default is at most two correction rounds after the first execution. Continue beyond
that when clear progress remains or the user requests it. Never create a replacement
child merely to dodge an unresolved correction.

### VALIDATE

Rerun the narrowest decisive acceptance subset in the primary session and inspect
behavior, not only exit status. Expand validation only when risk or impact warrants it;
do not unconditionally repeat every child check. Confirm no out-of-scope file changed,
no unrelated user edit was reverted, and no forbidden external mutation or secret
handling occurred.

### REVIEW (optional)

For high-risk changes or an explicit review request, spawn `reviewer` with a fresh
`fork_turns: none` packet. Require a read-only verdict of `ship`, `fix-first`, or
`rethink`. Capture actual sandbox and permission metadata; if the runtime broadens a
requested read-only profile, report residual risk and verify exact before/after state.
Any mutation invalidates the verdict and requires a fresh review. Ordinary low-risk
tasks do not require this extra role.

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
scope. The primary performs or verifies any authorized external mutation. A child
reporting failure is followed up in place rather than silently rerouted.
