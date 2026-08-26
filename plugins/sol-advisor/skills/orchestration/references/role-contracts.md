# Native Luna V2 role contracts

This document is the contract for the default native subagent V2 lane. The primary
selects one of five native roles and explicitly requests `gpt-5.6-luna` with `max`
effort.
The user-visible app-task Luna lane and the legacy Terra/Sol TOMLs are explicit
compatibility paths; they are not represented by these contracts.

## Routing gates

Before a spawn, the primary must establish:

1. the requested role is available in the native `spawn_agent` surface;
2. the request includes `model=gpt-5.6-luna`, `reasoning_effort=max`, and
   `fork_turns=none`; and
3. the spawn accepts that explicit route.

Role availability and spawn acceptance of the explicit Luna/max request are hard prerequisites
(hard gates for the delegation). If public spawn or rollout metadata
explicitly conflicts or shows a fallback, stop the affected delegation. If accepted
metadata omits model or effort,
record an `unobservable` warning and continue an ordinary task when there is no
conflict evidence. There is no silent fallback to another role, model, or effort.
`priority` has the same warning semantics when it is omitted. The primary model and
effort are not hard gates for using this skill.

## Cognitive decision boundary

Sol primary owns intent interpretation, product and architecture contracts, ownership,
authorization, risk/rollback and irreversible scope, secret handling, option selection,
final integration, residual-risk acceptance, and final acceptance. Luna roles gather bounded
evidence under an exact Sol-owned question or execute a decision-complete packet; they do not make, accept, or
silently widen those decisions. Explorers return evidence and options, reviewers return
findings and a recommendation, and Sol makes the final choice.

Judge delegation at a coherent write phase: the related repository mutations needed to reach the
next independently acceptable candidate state. Do not judge the whole user task, and do not
atomize a multi-file or cross-repository write phase into per-line or per-command `tiny` work.

The `worker` is the default for a decision-complete repository write phase. A primary-only
micro-edit is allowed only when packet and review overhead exceeds the saved context and all of
these hold: one repository; one already-inspected owned file; a genuinely atomic settled change;
no active second writer or overlapping/unclear dirty ownership; and at most one narrow writer-side
local non-browser check. An evidence-only packet may investigate an unresolved Sol-owned question.
If an execution prerequisite is unresolved or contradictory, the child returns `blocked` with
evidence and options.

Tracked test changes, tracked proxy/config changes, and dependency or lockfile changes are writer
work. Running a final narrow local non-browser acceptance subset remains allowed for primary.
When an explorer has one exact evidence question, primary works on a different decision dimension
or performs only a bounded purposeful spot-check; do not independently exhaust the same search
space while the explorer is active.

## Five role contracts

### `deep_explorer`

Use for ambiguous ownership, cross-package data flow, architecture-sensitive questions,
or legacy/generated-path reconciliation. It is read-only by default and returns the
smallest evidence-backed option set and tradeoffs for Sol to decide; it does not edit
product files or choose the final architecture.

### `explorer`

Use for bounded code tracing, configuration inspection, dependency lookup, and other
read-only evidence collection. It should answer the stated question without broad
cleanup or speculative changes.

### `worker`

Use for a decision-complete settled implementation with an exact owned file set. It is the sole writer
for those files in a shared worktree and is the default product writer. It preserves unrelated
edits, runs the requested focused checks, and reports actual changed files and evidence. It may
choose local implementation details inside the settled contract, but returns `blocked` rather
than inventing product, architecture, authorization, or risk decisions.

Product code, repository test code, tracked proxy/config changes, and dependency or lockfile changes
belong to the worker's coherent write phase. A worker may run the focused local checks required to
reach its next candidate state; primary may rerun only the narrowest final non-browser acceptance
subset.

When Git work is explicitly authorized, the native worker records the starting branch, base commit,
and `git status` before editing; stages only explicitly authorized changed files (the exact owned file set);
models commit and push as independent authorization flags (they may be granted together); never force-push
or rewrite history. The primary verifies remote SHA, tree, and readback acceptance after any authorized push.
Git permission does not imply Jira, deploy, or other external mutation.

Any authorized Git or Jira closeout is a decision-complete transaction: read before write; name the
exact target and action; carry independent authorization flags for commit, push, Jira, and deploy;
state order, stop conditions, and rollback boundary; then return post-write readback. Permission for
one mutation never implies another, and the worker does not wait for drip-fed mechanical approval.

### `tester`

Use for focused tests, runtime reproduction, browser inspection, or failure
classification. The requested sandbox may be broadened by the host (for example,
`workspace-write`), but the default tester contract does not modify product code. The worker is
the default product writer; the only tester exception is a bounded repair/test-only exception with
explicit repair authorization, exact file ownership, a failed relevant check, and no active worker
writer, after which the tester is the sole writer for that owned set; otherwise return a blocker.
Disposable fixtures remain inside an explicitly scoped temporary area.

When UT/browser validation is in scope through the user request or repository instructions
against a repository-declared non-production environment, the tester owns the same browser session
end to end: login, visible CAPTCHA, accessible test OTP, UT execution, and evidence capture.
The primary validates the task packet and evidence, then sends any gap back to the same tester.
It does not repeat or take over browser/runtime QA unless the user explicitly asks the primary
to perform it. Authentication is bounded to the repository-declared test credential source,
and only after the primary records the target as non-production and keeps authorization in
scope. Never expose credential values or inspect stored browser passwords, cookies, local storage, or session storage.

For browser/runtime QA, the durable/default tool is only `$chrome:control-chrome`, used by one
Luna Max tester end to end with its Chrome-family browser-client runtime. The in-session
`tab.playwright` API is allowed. A later exact user selection for a particular task may override
this durable route, but a generic phrase such as “browser plugin” resolves to Chrome in this
configuration. Do not automatically substitute `$browser:control-in-app-browser`, BrowserMCP,
Computer Use, the standalone `$playwright` or `$playwright-interactive` skills, `npx playwright`,
or another Playwright CLI path. If the resolved tool or required extension/client is unavailable,
return `blocked` with the exact failure; for the default or generic Chrome route, point to
Settings -> Computer use. Never silently fall back.
Tool selection does not waive repository-required acceptance evidence; if the selected route cannot
produce it, return the incompatibility to Sol instead of changing tools or weakening acceptance.

Before the tester's first browser action, readiness must establish the exact URL and environment
class; candidate code/config state; a free writer slot; resolved browser tool and required
extension/client availability (for the default or generic Chrome route, `$chrome:control-chrome`
and its Chrome extension); dev-server command, port, health check, and cleanup owner; credential
source and allowed auth/test-data mutations; and pre-fix/post-fix steps with observable signals.
Sol settles target, environment, authorization, evidence, and risk. The worker owns required
tracked setup/config/code. The tester owns reversible runtime preparation, dependency materialization
that causes no tracked diff, the resolved browser session, dev-server lifecycle, and evidence.
Missing tracked write or unresolved product judgment returns `blocked` to Sol.

Use `blocked-auth` only for production/unknown targets, missing or rejected
credentials, user-controlled MFA/biometric/physical presence, account-lockout risk,
or a supported authentication attempt that remains blocked. An authentication
requirement alone is not a blocker.

### `reviewer`

Use only for a high-risk boundary or an explicit user request for independent review.
It is behaviorally read-only and uses the reviewer RETURN schema in the compact packet. It must
not implement its own fix or accept residual risk; its verdict is a recommendation for Sol.

## Writable-host observability for read-only roles

`deep_explorer`, `explorer`, `reviewer`, and a read-only `tester` must capture actual model,
effort, sandbox, and permission metadata supplied by the host, including a possible
`danger-full-access` profile. Record and compare worktree state before and after the run; host
metadata is not OS-enforced read-only isolation. If the worktree or any owned file mutates during
a behaviorally read-only run, fail and invalidate that result, then report the mutation for a fresh run.

## Compact task packet

Every child receives a self-contained packet with no full conversation or full diff
copy. Replace every placeholder before spawning:

```text
ROLE
Act as the <deep_explorer|explorer|worker|tester|reviewer> in Sol Advisor's native
Luna V2 lane.

ROUTE
agent_type=<deep_explorer|explorer|worker|tester|reviewer>
model=gpt-5.6-luna
reasoning_effort=max
fork_turns=none

OBJECTIVE
<Observable outcome and why it matters.>

FILES AND OWNERSHIP
You own only:
- <exact path or module>
You do not own:
- <excluded paths, parent-owned files, and other stacks>
Preserve unrelated edits and adapt to concurrent changes.

INTERFACES
- <Signatures, schemas, commands, routes, or compatibility behavior.>

SETTLED DECISIONS
- Intent and observable outcome: <settled decision>
- Architecture and contracts: <settled decision or not applicable>
- Scope and ownership: <settled decision>
- Authorization, risk, and rollback: <settled decision or not applicable>
- Acceptance evidence: <settled decision>
For evidence-only work, identify each unresolved choice as an exact Sol-owned question.
For execution work, if a prerequisite is unresolved or contradictory, do not invent it;
return `blocked` with the evidence and options Sol needs to decide.

TEST AUTHORIZATION (tester/browser tasks only)
- Target/environment class: <non-production | production | unknown | not applicable>
- Credential source: <repository-declared test credential source | not applicable>
- Allowed auth actions: <login, visible CAPTCHA, accessible test OTP | not applicable>
- External test-data mutation scope: <explicitly authorized scope | none | not applicable>
- Browser tool: <resolved/selected browser tool and client; default `$chrome:control-chrome` with Chrome family selector | not applicable>
- Playwright authorization: <explicit user request | forbidden | not applicable>
- Escalation conditions: <blocked-auth conditions above | not applicable>
For other roles, mark this section `not applicable`.

RUNTIME READINESS (tester/browser tasks only)
- Exact target URL/environment: <exact URL and environment class | not applicable>
- Candidate code/config state: <candidate revision and tracked setup state | not applicable>
- Writer slot: <free before browser action | not applicable>
- Resolved tool/extension: <selected/resolved tool and required extension/client available; default/generic Chrome extension when Chrome is resolved | not applicable>
- Dev-server command/port/health/cleanup owner: <command; port; health check; owner | not applicable>
- Reversible runtime/dependency prep: <prep causing no tracked diff | not applicable>
- Pre-fix/post-fix steps: <reproduction and acceptance steps | not applicable>
- Observable signals: <requests, UI state, logs, or other evidence | not applicable>
For other roles, mark this section `not applicable`.

CONSTRAINTS
- <Architecture, safety boundary, excluded scope, and settled decisions.>
- Do not commit, push, deploy, delete, upload, mutate external services, or handle
  secrets unless the user explicitly authorizes that action and the primary keeps it
  in scope.
- Do not implicitly authorize unrelated external test-data mutations, Jira operations,
  commit, push, deploy, upload, or other external actions.

CORRECTION STATE
correction_round: 0
continuation_reason: none
user_direction: none

VERIFICATION
- Run: <focused command> -> <concrete success evidence>
- Inspect: <file, diff, fixture, or runtime output> -> <required evidence>

RETURN
STATUS: complete | partial | blocked
CHANGES: <actual file-by-file summary, or none>
VERIFIED: <exact commands and output evidence>
JUDGMENT CALLS: <local execution decisions within the settled packet, or none>
GAPS: <unfinished work or blockers, or none>

REVIEWER RETURN (reviewer only)
VERDICT: ship|fix-first|rethink
REASON: <decisive reason>
VALIDATED: <checks and evidence that passed, or none>
UNVALIDATED: <checks not run or still unknown, or none>
FINDINGS: <precise findings, or none>
RECOMMENDATIONS: <required fixes or recommendations, or none>
RESIDUAL RISK: <most important remaining risk, or none>
```

The primary invokes the native tool explicitly:

```text
agent_type=<deep_explorer|explorer|worker|tester|reviewer>
model=gpt-5.6-luna
reasoning_effort=max
fork_turns=none
```

These fields are intentional routing, not a silent fallback.

## Same-agent correction

For a failed or incomplete result, the primary names the exact evidence gap and sends a
targeted `followup_task` (or `send_message`) to the same child. Do not create a
replacement child merely to avoid correction or reset the counter. The packet records
machine-readable `correction_round: 0` for the initial execution and `1` or `2` for corrections.
Beyond two requires a recorded `continuation_reason`; record `user_direction` as the quoted
direction when present, otherwise `none`. Continue beyond two only for clear progress or explicit
user direction; there is no hard short timeout. Each correction invalidates the previous acceptance
claim, so the primary reruns inspection and validation.

The primary applies the writable-host observability rule above to every behaviorally read-only
role, not only reviewers.

## Primary acceptance

The primary uses `list_agents`/`wait_agent`, spot-checks the actual worktree and complete
diff, confirms ownership, and reruns the narrowest decisive acceptance subset with local, non-browser checks.
Browser/runtime QA stays with the same tester end to end; the primary
inspects its evidence and follows up on gaps instead of repeating the browser session unless
the user explicitly asks the primary to perform it. Expand validation only when risk or impact warrants
it; a report without inspectable evidence is not acceptance evidence.
Independent read-only roles may run concurrently; a shared worktree has one writer, and no
child may commit, push, deploy, delete, upload, or handle secrets without explicit
authorization.
