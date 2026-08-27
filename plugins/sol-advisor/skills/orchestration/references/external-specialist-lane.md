# External specialist lane

This lane covers an external runtime that produces a bounded artifact or independent evidence for
Sol. It is not part of native Luna V2 and never adds another `agent_type`. Native Luna keeps exactly
`deep_explorer`, `explorer`, `worker`, `tester`, and `reviewer`.

## Admission

Use this lane only when durable user-level routing or an exact current request names an external
provider, runtime, model, or specialist workflow and the work benefits from expertise or a rendered
artifact that the primary/native lane does not provide as efficiently. Typical examples are a
high-fidelity design prototype, a domain-specific simulation, or an independent specialist report.

Do not commission an external artifact merely because a task mentions UI, design, or review. Keep
minor polish and tightly coupled judgment in Sol, route accepted implementation through the native
`worker`, and use the native `reviewer` for the high-risk independent review boundary it already owns.

## Authority and isolation

Sol owns:

- intent, product and architecture contracts, and the exact question or brief;
- provider/runtime/model/tool selection and any allowed fallback decision;
- authorization, secrets boundary, protected worktrees, and scratch location;
- option selection, artifact acceptance, implementation handoff, and residual risk.

The external specialist:

- owns only its declared scratch/project artifact surface;
- receives no production source ownership and does not implement production code;
- does not commit, push, deploy, delete, upload, mutate external services, or handle secrets unless
  the user explicitly authorizes the exact action and Sol keeps it in scope;
- returns evidence and artifacts for Sol to inspect rather than declaring final acceptance.

If the runtime is writable or its isolation is not OS-enforced, record protected repository HEAD and
worktree state before and after. Any unexpected protected-worktree mutation invalidates the result.
Never bind a writable external runtime directly to a production repository merely for convenience;
use an isolated project or scratch root and copy only the minimum reviewed context it needs.

## Exact routing and fallback

Preflight the named provider/runtime/model/tool. If the exact route is unavailable, authentication
fails, or public metadata conflicts with the requested route, return `blocked`. Never silently
substitute another provider, model, local agent, native Luna role, or weaker permission mode.
Metadata that simply omits a requested field is `unobservable`; continue only when the active
user-level contract explicitly permits that warning and there is no conflict evidence.

## Commission packet

Send a compact, self-contained packet. Do not forward the full conversation, private scratchpad,
complete repository, secrets, credentials, cookies, or unrelated diffs.

```text
SPECIALIST
<Named provider/runtime/model/tool and specialist purpose.>

OBJECTIVE
<Observable artifact/evidence outcome and why it matters.>

INPUT CONTEXT
- <Reviewed excerpts, screenshots, design tokens, schemas, or references.>
- <No unnecessary absolute paths or secret-bearing files.>

PROTECTED WORKTREES
- <Repository, starting HEAD, and clean/dirty-state digest.>

OWNERSHIP
- Specialist owns only: <isolated project/scratch/artifact paths>.
- Specialist does not own: <production repositories and excluded paths>.

SETTLED DECISIONS
- Intent and observable outcome: <settled>
- Product/architecture constraints: <settled or not applicable>
- Exact provider/runtime/model/tool: <settled>
- Authorization, isolation, risk, and rollback: <settled>
- Acceptance evidence: <settled>

CONSTRAINTS
- <Scope, output format, forbidden actions, privacy and safety boundaries.>
- Do not implement production code.
- Do not silently widen the task or choose a fallback route.

CORRECTION STATE
external_correction_round: 0
continuation_reason: none
user_direction: none

RETURN
STATUS: complete | partial | blocked
ROUTE EVIDENCE: <requested and observed provider/runtime/model/tool, or unobservable fields>
ARTIFACTS: <actual artifact identifiers/paths/URLs, or none>
EVIDENCE: <inspectable evidence and checks>
ASSUMPTIONS: <assumptions, or none>
GAPS: <unfinished work or blockers, or none>
PROTECTED STATE: <before/after comparison>
```

## Lifecycle

### PREPARE

Sol settles the brief, accepted input context, exact route, isolation, protected repositories,
acceptance evidence, correction budget, and rollback. If product direction is unresolved, the
external run may explore bounded alternatives, but Sol still chooses the final direction.

### PREFLIGHT

Verify availability and authentication without exposing credentials. Confirm an isolated scratch or
project surface, record protected worktree state, and ensure there is no active writer whose ownership
could make the before/after comparison ambiguous.

### COMMISSION

Start exactly one logical run with a stable idempotency/request identifier when the runtime supports
it. A lost response must not cause a duplicate run with a new identity. External commission tools are
called by Sol; do not nest the external specialist inside a native Luna child merely to imitate another
native role.

### MONITOR

Use the runtime's status/cancel interface. Do not burn model context on rapid polling. Cancel only for
a user stop, a safety/authorization boundary, or a clearly abandoned run.

### INSPECT

Treat `succeeded` as transport status, not acceptance. Inspect the actual artifact or evidence and
require the declared deliverables. A successful status with no required artifact is
`succeeded-no-output` and is not accepted. Recompare protected worktree state and invalidate the run
on unexpected mutation.

### CORRECT

Send a targeted correction to the same logical specialist project/session when supported. The
external correction counter is separate from native Luna correction rounds. Default to one targeted
correction and allow at most two unless the user explicitly directs continuation or there is clearly
measurable progress; record `continuation_reason` and `user_direction` beyond the default.

### ACCEPT / HAND OFF

Sol accepts, rejects, or requests correction. Only after acceptance may Sol create a decision-complete
native `worker` packet that translates the artifact into production implementation. The worker owns
production files and tests; the external specialist does not. Browser/runtime QA remains with the
native `tester` under the configured browser contract.

## Failure and rollback

On unavailable routing, authentication failure, missing output, unexpected protected-worktree
mutation, or an uninspectable artifact, stop and report the exact blocker. Preserve the isolated
project for diagnosis unless the user authorized deletion. Rollback is limited to the lane's own
scratch/artifact/config changes; never delete user projects or revert unrelated work automatically.
