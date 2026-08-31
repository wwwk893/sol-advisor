# Native mixed-model V2 role contracts

This document is the contract for the default native subagent V2 lane. The primary
selects one of five logical roles and pins the model and reasoning effort from the balanced
routing matrix below. The user-visible app-task Luna lane and the legacy Terra/Sol TOMLs
remain explicit compatibility paths; they are not represented by these contracts.

## Routing gates

Resolve the role first, then resolve exactly one model route:

| Role / class | Model | Effort |
|---|---|---|
| `explorer` | `gpt-5.6-luna` | `high` |
| `deep_explorer` | `gpt-5.6-terra` | `high` |
| `worker` mechanical fast-path | `gpt-5.6-luna` | `high` |
| `worker` normal | `gpt-5.6-terra` | `high` |
| `tester` | `gpt-5.6-luna` | `high` |
| `reviewer` normal | `gpt-5.6-sol` | `medium` |
| `reviewer` critical-risk | `gpt-5.6-sol` | `high` |

The specialized role presets are immutable Luna/Max carriers and cannot carry this matrix. Every
mixed-lane spawn uses `agent_type=default`; `logical_role` and `route_class` remain packet fields.
Before a spawn, the primary must establish:

1. the default carrier is available in the native `spawn_agent` surface;
2. the task satisfies the selected route class and the request includes the exact resolved
   `model`, `reasoning_effort`, and `fork_turns=none`; and
3. the spawn accepts that explicit route.

Role availability and spawn acceptance of the exact resolved route are hard prerequisites.
If public spawn or rollout metadata explicitly conflicts or shows a fallback, stop the affected
delegation. If accepted metadata omits model or effort, record an `unobservable` warning and
continue an ordinary task when there is no conflict evidence. There is no silent fallback to
another role, model, effort, or provider. `priority` has the same warning semantics when it is
omitted. The primary model and effort are not hard gates for using this skill.

### Worker route selection

The `worker` mechanical fast-path may use Luna High only when all predicates are satisfied:

- the exact owned file set is known and contains at most two files for the coherent write phase;
- intent, interfaces, architecture/contracts, authorization, risk, and acceptance are fully settled;
- there is no cross-package/cross-repository runtime or data-flow reasoning left to perform;
- there is no dependency/lockfile change, tracked config migration, or generated/legacy reconciliation;
- there is no ambiguous writer ownership or overlapping dirty state; and
- one focused local non-browser verification is sufficient to reach the candidate state.

If any predicate is false or unknown, use the normal Terra High worker route. Do not split a larger
write phase merely to manufacture eligibility for the mechanical fast-path.

### Reviewer route selection

The normal independent-review route is Sol Medium. Escalate to the critical-risk Sol High route when
the review crosses production authentication or access-control boundaries, secret-handling or
security-sensitive privilege boundaries, destructive or irreversible data/migration behavior,
credible data-loss risk, or another explicitly identified high-consequence residual-risk decision.
The reviewer still recommends; Sol primary accepts or rejects residual risk.

## Cognitive decision boundary

Sol primary owns intent interpretation, product and architecture contracts, ownership,
authorization, risk/rollback and irreversible scope, secret handling, option selection,
final integration, residual-risk acceptance, and final acceptance. Native roles gather bounded
evidence under an exact Sol-owned question or execute a decision-complete packet; they do not make,
accept, or silently widen those decisions. Explorers return evidence and options, reviewers return
findings and a recommendation, and Sol makes the final choice.

## Proactive reconnaissance boundary

For a non-trivial repository task, Sol first classifies which facts are already known and which
require repository evidence. If the runtime path, implementation location, ownership,
callers/callees, relevant tests, configuration, generated or legacy path, or cross-package data
flow is unknown and resolving it requires broad search, the default is an evidence-only
`explorer` or `deep_explorer` packet before Sol performs that search itself.

Sol may inspect only enough seed material to state the user goal, known constraints, search roots,
and exact evidence questions. It must not map the same repository space, read a long chain of
candidate files, or independently reconstruct the full call graph before or during the child run.
`explorer` owns one bounded subsystem trace; `deep_explorer` owns ambiguous ownership,
cross-package or cross-repository flow, competing implementations, or legacy/generated
reconciliation. Orthogonal read-only questions may run concurrently within the ordinary child
ceiling.

The child is an evidence-compression layer, not a decision owner. Every material claim returns
inspectable `path:line-line` or primary-source evidence, labels observation versus inference,
names contradictions and unknowns, and identifies the smallest decisive regions Sol should read
next. Sol spot-checks those regions rather than repeating the broad search. Missing, stale, or
contradictory evidence goes back to the same child as a targeted correction.

Do not add reconnaissance when the exact file/runtime path and contract are already known and the
task is a status answer, strict micro-edit, or decision-complete worker phase. The purpose is to
save primary context without adding ceremony.

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
product files or choose the final architecture. Use Terra High because this role is the
long-context and architecture-sensitive reconnaissance lane. Use the reconnaissance packet and
return schema below so competing paths, observations, inferences, and unknowns remain inspectable.

### `explorer`

Use for bounded code tracing, configuration inspection, dependency lookup, and other
read-only evidence collection. It should answer the stated question without broad
cleanup or speculative changes. It returns cited decisive regions and search coverage,
not a narrative dump or an implementation decision. Use Luna High for this frequent,
bounded, latency-sensitive evidence route.

### `worker`

Use for a decision-complete settled implementation with an exact owned file set. It is the sole writer
for those files in a shared worktree and is the default product writer. It preserves unrelated
edits, runs the requested focused checks, and reports actual changed files and evidence. It may
choose local implementation details inside the settled contract, but returns `blocked` rather
than inventing product, architecture, authorization, or risk decisions.

Product code, repository test code, tracked proxy/config changes, and dependency or lockfile changes
belong to the worker's coherent write phase. A worker may run the focused local checks required to
reach its next candidate state; primary may rerun only the narrowest final non-browser acceptance
subset. The normal route is Terra High; Luna High is allowed only through the mechanical fast-path
predicates above.

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

For browser/runtime QA, one Luna High tester owns the session end to end. An exact user-selected
browser tool always wins and is preflighted on its own; never silently fall back from that choice.
For default or generic “browser plugin” QA, probe actual capability rather than infer from OS labels and record the `selected route`,
availability, and fallback reason before dispatch. Use this ordered ladder: (1) durable
`$chrome:control-chrome` with its Chrome extension and Chrome-family browser-client (desktop
preferred); (2) an officially registered `chrome-devtools-mcp` with a supported local stable Chrome,
headless and isolated (VPS/headless preferred); (3) an already-installed runnable Playwright CLI as
the last fallback; (4) return `blocked` with the exact missing capability. Do not install or download
a browser tool during an ordinary tester run. The in-session `tab.playwright` API is allowed; do not
substitute `$browser:control-in-app-browser`, BrowserMCP, Computer Use, or another unselected tool.
If the default Chrome extension is unavailable, record that capability as unavailable, point to Settings -> Computer use,
and continue to the next default route; block only when all default capabilities fail.
Human-visible auth/CAPTCHA, user-controlled MFA/biometric/physical presence, or an existing
desktop-session requirement on headless must stop and return to Sol for an explicit desktop Chrome
reroute; never silently switch, bypass, or inspect stored auth state. Tool selection does not waive
repository-required acceptance evidence; if the selected route cannot produce it, return the
incompatibility to Sol instead of changing tools or weakening acceptance.

Before the tester's first browser action, readiness must establish the exact URL and environment
class; candidate code/config state; a free writer slot; the selected route's client/capability (the
desktop Chrome route requires `$chrome:control-chrome` and its extension; the headless route requires
registered `chrome-devtools-mcp` with supported Chrome; the last fallback requires an installed,
runnable Playwright CLI); dev-server command, port, health check, and cleanup owner; credential
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
Use Sol Medium normally and Sol High only for the critical-risk predicates above.

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
Act as the logical <deep_explorer|explorer|worker|tester|reviewer> in Sol Advisor's native
mixed-model V2 lane.

ROUTE
carrier_agent_type=default
logical_role=<deep_explorer|explorer|worker|tester|reviewer>
route_class=<default|mechanical-fast-path|normal|critical-risk>
model=<resolved gpt-5.6-luna|gpt-5.6-terra|gpt-5.6-sol>
reasoning_effort=<resolved medium|high>
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

RECONNAISSANCE (explorer/deep_explorer only)
- Exact evidence questions: <bounded questions whose answers change Sol's decision>
- Search boundary: <repository roots, packages, generated/legacy areas, and explicit exclusions>
- Primary seed evidence: <what Sol already inspected; do not repeat it without cause>
- Required evidence: <path:line-line, symbols, callers, tests/config, or primary-source facts>
- Stop condition: <questions answered with cited evidence, or a precise blocker/unknown>
For other roles, mark this section `not applicable`.

TEST AUTHORIZATION (tester/browser tasks only)
- Target/environment class: <non-production | production | unknown | not applicable>
- Credential source: <repository-declared test credential source | not applicable>
- Allowed auth actions: <login, visible CAPTCHA, accessible test OTP | not applicable>
- External test-data mutation scope: <explicitly authorized scope | none | not applicable>
- Browser tool: <exact selected tool/client, or capability-first default ladder with Chrome family selector | not applicable>
- Playwright authorization: <explicit user request, or already-installed last fallback after capability probe | not applicable>
- Escalation conditions: <blocked-auth conditions above | not applicable>
For other roles, mark this section `not applicable`.

RUNTIME READINESS (tester/browser tasks only)
- Exact target URL/environment: <exact URL and environment class | not applicable>
- Candidate code/config state: <candidate revision and tracked setup state | not applicable>
- Writer slot: <free before browser action | not applicable>
- Resolved/selected browser tool and extension: <selected/resolved tool, required extension/client, and capability probe available | not applicable>
- Selected route/availability: <route, availability, and fallback reason recorded before browser action | not applicable>
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

For `explorer` and `deep_explorer`, replace the generic `RETURN` block with this evidence-oriented
contract:

```text
RECONNAISSANCE RETURN
STATUS: complete | partial | blocked
ANSWER: <direct answer in at most six lines; distinguish observed facts from inference>
RUNTIME PATH: <ordered path:line-line -> path:line-line chain, or not established>
RELEVANT REGIONS:
- <path:line-line> | <symbol> | observed|inferred | <why it matters> | confidence=<high|medium|low>
CONTRACT / TEST EVIDENCE:
- <path:line-line or primary source> | <what it proves>
CONTRADICTIONS / UNKNOWNS:
- <conflict, missing evidence, or none>
SEARCH COVERAGE:
- checked: <roots, queries, callers, tests/config, generated/legacy paths>
- excluded: <out-of-scope areas>
READ NEXT:
- <smallest decisive path:line-line regions Sol should inspect>
SOL DECISION NEEDED:
- <exact choice that remains Sol-owned, or none>
```

The native spawn API contains only these `spawn_agent` arguments:

```text
agent_type=default
model=<resolved gpt-5.6-luna|gpt-5.6-terra|gpt-5.6-sol>
reasoning_effort=<resolved medium|high>
fork_turns=none
```

The ROUTE packet metadata above is intentional routing, not a silent fallback.

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
For explorer handoffs, it starts with `ANSWER` and `READ NEXT`, inspects the cited decisive regions,
and checks material observations without recreating the repository-wide search. Missing or conflicting
evidence is corrected with the same explorer. Browser/runtime QA stays with the same tester end to end; the primary
inspects its evidence and follows up on gaps instead of repeating the browser session unless
the user explicitly asks the primary to perform it. Expand validation only when risk or impact warrants
it; a report without inspectable evidence is not acceptance evidence.
Independent read-only roles may run concurrently; a shared worktree has one writer, and no
child may commit, push, deploy, delete, upload, or handle secrets without explicit
authorization.
