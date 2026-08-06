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

## Five role contracts

### `deep_explorer`

Use for ambiguous ownership, cross-package data flow, architecture-sensitive questions,
or legacy/generated-path reconciliation. It is read-only by default and returns the
smallest evidence-backed recommendation; it does not edit product files.

### `explorer`

Use for bounded code tracing, configuration inspection, dependency lookup, and other
read-only evidence collection. It should answer the stated question without broad
cleanup or speculative changes.

### `worker`

Use for a settled implementation with an exact owned file set. It is the sole writer
for those files in a shared worktree. It preserves unrelated edits, runs the requested
focused checks, and reports actual changed files and evidence.

### `tester`

Use for focused tests, runtime reproduction, browser inspection, or failure
classification. The requested sandbox may be broadened by the host (for example,
`workspace-write`), but the default tester contract does not modify product code. A
parent may explicitly assign a bounded repair/test-only change with exact ownership;
otherwise return a blocker. Disposable fixtures remain inside an explicitly scoped
temporary area.

When UT/browser validation is in scope through the user request or repository instructions
against a repository-declared non-production environment, the tester owns the same browser session
end to end: login, visible CAPTCHA, accessible test OTP, UT execution, and evidence capture.
The primary validates the task packet and evidence, then sends any gap back to the same tester.
It does not repeat or take over browser/runtime QA unless the user explicitly asks the primary
to perform it. Authentication is bounded to the repository-declared test credential source,
and only after the primary records the target as non-production and keeps authorization in
scope. Never expose credential values or inspect stored browser passwords, cookies, local storage, or session storage.

Use `blocked-auth` only for production/unknown targets, missing or rejected
credentials, user-controlled MFA/biometric/physical presence, account-lockout risk,
or a supported authentication attempt that remains blocked. An authentication
requirement alone is not a blocker.

### `reviewer`

Use only for a high-risk boundary or an explicit user request for independent review.
It is behaviorally read-only and returns one verdict: `ship`, `fix-first`, or
`rethink`, with precise findings and residual risk. It must not implement its own fix.

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

TEST AUTHORIZATION (tester/browser tasks only)
- Target/environment class: <non-production | production | unknown | not applicable>
- Credential source: <repository-declared test credential source | not applicable>
- Allowed auth actions: <login, visible CAPTCHA, accessible test OTP | not applicable>
- External test-data mutation scope: <explicitly authorized scope | none | not applicable>
- Escalation conditions: <blocked-auth conditions above | not applicable>
For other roles, mark this section `not applicable`.

CONSTRAINTS
- <Architecture, safety boundary, excluded scope, and settled decisions.>
- Do not commit, push, deploy, delete, upload, mutate external services, or handle
  secrets unless the user explicitly authorizes that action and the primary keeps it
  in scope.
- Do not implicitly authorize unrelated external test-data mutations, Jira operations,
  commit, push, deploy, upload, or other external actions.

VERIFICATION
- Run: <focused command> -> <concrete success evidence>
- Inspect: <file, diff, fixture, or runtime output> -> <required evidence>

RETURN
STATUS: complete | partial | blocked
CHANGES: <actual file-by-file summary, or none>
VERIFIED: <exact commands and output evidence>
JUDGMENT CALLS: <decisions, or none>
GAPS: <unfinished work or blockers, or none>
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
replacement child merely to avoid correction. The normal budget is one execution plus
at most two correction rounds. Continue when there is clear progress or the user asks
for it; there is no hard short timeout. Each correction invalidates the previous
acceptance claim, so the primary reruns inspection and validation.

## Reviewer verdict and isolation

The reviewer returns:

```text
VERDICT: ship | fix-first | rethink
REASON: <decisive evidence-backed reason>
FINDINGS: <precise paths and required fixes, or none>
RESIDUAL RISK: <most important remaining risk, or none>
```

Observe the actual sandbox policy and permission profile supplied by the runtime. If a
tester or reviewer requests read-only but the host reports a writable profile, report
that residual risk and verify before/after state. Do not claim OS-enforced read-only
isolation unless the runtime says so. Any mutation during an intended read-only review
stops that review and requires a fresh verdict.

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
