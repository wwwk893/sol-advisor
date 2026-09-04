# Sol Advisor

Sol Advisor 0.7.1 is a small Codex orchestration skill. After installation it is the
default route for every new user request. Activation does not force a child: simple
answers, status-only, install-only, and no-subagent requests stay primary-only. Authorized
commit/push prefers reusing the implementation worker or starting one bounded worker with
an exact-scope packet, reducing primary-context token use. Other engineering work that
benefits from delegation uses the native multi-agent V2 runtime. The primary session owns
the highest-value judgment: intent, architecture/contracts, authorization, risk/rollback,
option selection, integration, and acceptance. Runtime-configured Sol agents handle bounded
evidence under an exact question or execution after a decision-complete packet. For non-trivial work
with an unknown runtime path, ownership, or caller flow, start evidence-only reconnaissance: `explorer` for a
bounded trace; `deep_explorer` for cross-package/cross-repository, competing, legacy-generated, or architecture-sensitive
paths. The primary frames the question without exhausting the same search; Status answers, strict micro-edits, and decision-complete worker phases skip RECON only when location/runtime path and contract are known; packet and review overhead can keep known paths primary/worker.

### Coordination and latency guardrails in 0.7.1

At spawn, Sol records an active-child ownership ledger covering the child role/objective, owned evidence/files/tests/review,
acceptance relevance, explicitly allowed orthogonal primary work, and dependent phases. While a child is nonterminal,
the primary is limited to that named orthogonal work or a bounded non-overlapping spot-check; it does not duplicate or
take over the child's evidence search, implementation, tests, browser/runtime QA, or review because the child is slow or
quiet. The shared worktree remains one-writer.

Before a dependent phase (including review or acceptance validation) or ACCEPT, Sol inspects state and waits for every
acceptance-relevant predecessor to reach terminal state, then inspects and dispositions its handoff and artifacts.
`failed`, `blocked`, and authorized interruption require a recorded disposition; missing evidence cannot be silently
waived and partial output is not accepted. Prefer a long `wait_agent`; `list_agents` is for preflight/state transitions
or user-requested status, and one factual `send_message` is used only when progress evidence is genuinely needed.
Silence is not abandonment, and `interrupt_agent` is limited to user stop, safety boundary, or evidence-supported
abandonment.
When `wait_agent` yields only a timeout with no new child output, blocker, state transition, or user decision, the primary
emits no user-facing status/chatter; updates are reserved for a return/evidence, actual transition, blocker, or needed
decision.

Fresh cited evidence is reusable only when scope, branch/base, dirty ownership, relevant config/runtime, and contracts
are unchanged; otherwise invalidate/recon. The worker owns tracked tests/config/dependencies, one tester owns browser
runtime QA end to end, and Sol runs the narrowest local non-browser acceptance subset only after predecessors are
terminal. The initial worker packet covers the whole coherent implementation/check/return phase. Tester receives one
batched acceptance packet after the final candidate and repeats only after drift or a precise evidence gap. Reviewer is
high-risk or explicit only, after the final candidate, with at most one logical reviewer per candidate. The
deterministic file-backed fixture is `plugins/sol-advisor/skills/orchestration/evals/coordination_cases.json`, checked
by a pure state/action evaluator and `scripts/verify-coordination.sh`; reports include
`reports/output_quality_scorecard.md`, the skills/orchestration-scoped Yao trust report, and the
machine-checked `reports/plugin_shell_trust.md/.json` inventory for every shipped shell entrypoint.
Unavailable runtime A/B latency/token and service-tier metadata remain missing evidence.

The interface's `activation.mode: manual` is adapter invocation metadata only; the global AGENTS default supplies
always-on routing.
Browser/runtime QA stays with one tester. An exact later user selection (user-selected browser tool)
always wins, is preflighted on its own, and never falls back. For default or generic “browser plugin”
QA, probe actual capability rather than infer from OS labels, record the `selected route`, availability,
and fallback reason, then use this ladder: (1) `$chrome:control-chrome` with its Chrome extension and
Chrome-family browser-client (desktop preferred); (2) an officially registered `chrome-devtools-mcp`
with supported local stable Chrome, headless and isolated (VPS/headless preferred); (3) an
already-installed runnable Playwright CLI as the last fallback; (4) block with the exact missing
capability. Do not install or download a browser tool during an ordinary tester run. The in-session
`tab.playwright` API is allowed; do not substitute Browser, BrowserMCP, Computer Use, or another
unselected tool. If the default Chrome extension is unavailable, record that capability as unavailable,
point to Settings -> Computer use, and continue to the next default route; block only when all default
capabilities fail. Human-visible auth/CAPTCHA, user-controlled MFA/biometric/physical presence, or an
existing desktop-session requirement on headless must stop and return to Sol for an explicit desktop
Chrome reroute; never silently switch, bypass, or inspect stored auth state.
The only route opt-out is an explicit request not to use Sol Advisor or orchestration
for the current task.

## Upstream attribution

This release is based on [DannyMac180/sol-advisor](https://github.com/DannyMac180/sol-advisor).
Daniel McAteer is the original author; the always-on routing adaptation is maintained
by [wwwk893](https://github.com/wwwk893) under the MIT License.

## Default native mixed Sol V2 lane

The native lane selects one exact carrier, logical role, route class, model, and effort. The five role contracts are:

| Logical role / class | Carrier | Model / effort | Default mutation boundary |
|---|---|---|---|
| `explorer` / normal | `default` | `gpt-5.6-sol` / low | Read-only |
| `deep_explorer` / normal | `default` | `gpt-5.6-sol` / medium | Read-only |
| `worker` / normal | `default` | `gpt-5.6-sol` / medium | Sole writer |
| `reviewer` / normal | `default` | `gpt-5.6-sol` / medium | Read-only verdict |
| `reviewer` / critical-risk | `default` | `gpt-5.6-sol` / high | Read-only verdict |
| `tester` / normal | `tester` | `gpt-5.6-luna` / max | No product code by default |

Exact matrix: `explorer=default/gpt-5.6-sol/low/normal`; `deep_explorer=default/gpt-5.6-sol/medium/normal`;
`worker=default/gpt-5.6-sol/medium/normal`; `reviewer.normal=default/gpt-5.6-sol/medium/normal`;
`reviewer.critical-risk=default/gpt-5.6-sol/high/critical-risk`; `tester=tester/gpt-5.6-luna/max/normal`.
An exact Luna worker/explorer prompt is an explicit compatibility-route override and an activation fixture, not evidence of the default route.

Use the native tools `spawn_agent`, `list_agents`, `wait_agent`, `followup_task`,
`send_message`, and `interrupt_agent`. A normal task runs once and receives at most two
targeted correction rounds by default. Continue beyond that only when there is clear
progress or the user asks for it; there is no rigid short timeout. Three concurrent
agents is a suggested ceiling, not a correctness limit. Read-only investigations may
run in parallel, but a shared worktree has one writer at a time.

Carrier availability and an accepted spawn with the exact resolved route are hard
requirements. If public spawn or rollout metadata explicitly conflicts or shows a
fallback, stop; if accepted routing metadata omits model or effort, record an
`unobservable` warning and continue an ordinary task when there is no conflict evidence.
Sol routes never request fast mode or priority service tier. Explicit `fast_mode=true` or
`service_tier=priority` blocks; absent metadata is `unobservable`, not proof it is disabled.

The native call pins the route explicitly:

```text
carrier_agent_type=<default|tester>
logical_role=<deep_explorer|explorer|worker|tester|reviewer>
route_class=<normal|critical-risk>
model=<gpt-5.6-sol|gpt-5.6-luna>
reasoning_effort=<low|medium|high|max>
fork_turns=none
```

Every child receives a compact role-complete packet with objective, ownership, interfaces,
constraints, verification, and a structured return. Evidence-only packets may carry exact
Sol-owned questions; execution packets must settle architecture, authorization, and risk first.
Unresolved execution judgment returns `blocked` to Sol. Children must preserve
unrelated edits and may not commit, push, deploy, delete, upload, or handle secrets
unless the user explicitly authorizes that action and the primary keeps it in scope.
When a child fails, correct the specification and follow up with that same child. The
primary spot-checks the actual diff and reruns the narrowest decisive acceptance subset
with local, non-browser checks. It inspects tester evidence and sends gaps back to the same tester
instead of repeating browser/runtime QA. The tester uses the exact later user-selected tool when one
is named; otherwise it probes capability, records the selected route and fallback reason, and uses the
ordered desktop Chrome extension, registered headless `chrome-devtools-mcp`, or already-installed
runnable Playwright CLI ladder. Its in-session `tab.playwright` API remains allowed, but no unselected
tool or auto-install is permitted. Human-visible auth, CAPTCHA, MFA, biometric, physical-presence, or
existing-desktop-session requirements on headless stop the run and return to Sol for an explicit desktop
Chrome reroute without bypassing or inspecting stored auth state. It expands validation only when risk
or impact warrants it. Lightweight or tightly coupled changes may be implemented directly in the primary
session.

The native lane does not require app-task tools, a nested Codex CLI, or an installed
companion role. Do not install or remove roles automatically.

## Explicit compatibility lanes

The following paths are retained for users who explicitly choose them; neither is the
default native V2 lane:

- **User-visible app-task Luna lane:** say “Use the Luna task lane” in the current
  request. The primary then follows
  [the compatibility contract](plugins/sol-advisor/skills/orchestration/references/luna-task-lane.md)
  and uses the app task tools only for that explicitly selected lane.
- **Legacy Terra/Sol companion lane:** the shipped
  `sol-advisor-terra-implementer.toml` and `sol-advisor-sol-reviewer.toml` files and
  `scripts/install-agents.sh` remain available for explicit compatibility. The
  installer is never called by the native V2 workflow; invoke it deliberately when a
  local user wants those roles.

## Install the plugin

For checkout-relative commands, first enter the repository:

```sh
cd /absolute/path/to/sol-advisor
```

Core verification requires POSIX sh, jq, python3, and shasum. The explicit
legacy installer also needs `python3` or GNU readlink for canonicalization; if neither
works, it refuses the target instead of using an unsafe fallback.

```sh
codex plugin marketplace add wwwk893/sol-advisor --ref main
codex plugin add sol-advisor@sol-advisor
```

After installation, start a new task so the native V2 role catalog is current. Then
invoke `$sol-advisor:orchestration` or describe the work normally; the skill routes the
request by default. It preflights the native runtime, spawns only the selected role
when delegation adds value, monitors it, and keeps acceptance coordination in the primary
session while the same tester owns browser/runtime QA. No measured speed improvement is claimed;
A/B latency/token/service-tier evidence remains missing.

For a hosted update, run:

```sh
codex plugin marketplace upgrade sol-advisor
```

After upgrading, start a new task so the updated skill is loaded.

The compatibility installer accepts an explicit destination when needed:

```sh
sh plugins/sol-advisor/scripts/install-agents.sh --target-dir /absolute/path/agents
sh plugins/sol-advisor/scripts/install-agents.sh --target-dir /absolute/path/agents --check
```

It does not read `HOME` or `CODEX_HOME` before parsing an explicit target. It refuses a
root-equivalent target and never overwrites a modified or unsafe destination.

## Runtime evidence

Native spawn/details metadata is the first routing evidence. When model or effort is
present, it must agree with the explicit request; when omitted, report an
`unobservable` warning rather than inferring a fallback. The read-only
`scripts/inspect-agent-runtime.sh` helper can inspect one exact rollout filename when
those fields are available and emits only an allowlisted routing object. Pass its expected carrier,
logical role, route class, model, effort, and fork arguments. Expected logical role/route class are
request intent, not observed runtime facts; absent host observations remain `unobservable`. Explicitly
observed mismatches block. Missing model, effort, fast, or service-tier observations are `unobservable`. Sol fast/priority conflicts block;
unavoidably observed tester priority is returned as a warning, never requested. Missing or ambiguous
sandbox, permission, or working-directory fields still fail. The helper never prints prompts, secrets,
or arbitrary rollout payloads.

Run repository checks with:

```sh
sh plugins/sol-advisor/scripts/verify.sh
```

## Production quality gates (optional development checks)

These checks use the installed Yao meta-skill only during development; the plugin's
core verifier does not depend on Yao:

```sh
YAO_DIR="${CODEX_HOME:-$HOME/.codex}/skills/yao-meta-skill"
uv run --no-project --python 3.11 --with pyyaml python "$YAO_DIR/scripts/validate_skill.py" plugins/sol-advisor/skills/orchestration
uv run --no-project --python 3.11 --with pyyaml python "$YAO_DIR/scripts/resource_boundary_check.py" plugins/sol-advisor/skills/orchestration
uv run --no-project --python 3.11 python "$YAO_DIR/scripts/context_sizer.py" plugins/sol-advisor/skills/orchestration --json
uv run --no-project --python 3.11 python "$YAO_DIR/scripts/trigger_eval.py" \
  --description-file plugins/sol-advisor/skills/orchestration/SKILL.md \
  --cases plugins/sol-advisor/skills/orchestration/evals/trigger_cases.json \
  --semantic-config plugins/sol-advisor/skills/orchestration/evals/semantic_config.json
```
