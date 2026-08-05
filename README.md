# Sol Advisor

Sol Advisor is a small Codex orchestration skill. After installation it is the
default route for every new user request. Activation does not force a child: simple
answers, status-only, install-only, commit/push-only, and no-subagent requests stay
primary-only, while engineering work that benefits from delegation uses the native
multi-agent V2 runtime. The primary session owns requirements, architecture,
spot-checks, and acceptance, while runtime-configured Luna agents handle bounded work.
The only route opt-out is an explicit request not to use Sol Advisor or orchestration
for the current task.

## Upstream attribution

This release is based on [DannyMac180/sol-advisor](https://github.com/DannyMac180/sol-advisor).
Daniel McAteer is the original author; the always-on routing adaptation is maintained
by [wwwk893](https://github.com/wwwk893) under the MIT License.

## Default native Luna V2 lane

The native lane selects a role for the task and explicitly requests
`gpt-5.6-luna` with `max` effort. The five available role contracts are:

| Role | Use it for | Default mutation boundary |
|---|---|---|
| `deep_explorer` | Ambiguous, cross-module, or architecture-sensitive investigation | Read-only |
| `explorer` | Bounded code/data tracing and evidence collection | Read-only |
| `worker` | A settled implementation with one owned file set | The sole writer in a shared worktree |
| `tester` | Focused tests, runtime reproduction, and failure classification | No product code by default; parent-assigned bounded repair may be allowed |
| `reviewer` | High-risk or user-requested independent review | Read-only verdict |

Use the native tools `spawn_agent`, `list_agents`, `wait_agent`, `followup_task`,
`send_message`, and `interrupt_agent`. A normal task runs once and receives at most two
targeted correction rounds by default. Continue beyond that only when there is clear
progress or the user asks for it; there is no rigid short timeout. Three concurrent
agents is a suggested ceiling, not a correctness limit. Read-only investigations may
run in parallel, but a shared worktree has one writer at a time.

Role availability and an accepted spawn with the requested Luna/max route are hard
requirements. If public spawn or rollout metadata explicitly conflicts or shows a
fallback, stop; if accepted routing metadata omits model or effort, record an
`unobservable` warning and continue an ordinary task when there is no conflict evidence.
`priority` is requested/capability evidence with the same warning semantics. The primary
model or effort is not a hard gate for this skill.

The native call pins the route explicitly:

```text
agent_type=<deep_explorer|explorer|worker|tester|reviewer>
model=gpt-5.6-luna
reasoning_effort=max
fork_turns=none
```

Every child receives a compact self-contained packet with objective, ownership,
interfaces, constraints, verification, and a structured return. Children must preserve
unrelated edits and may not commit, push, deploy, delete, upload, or handle secrets
unless the user explicitly authorizes that action and the primary keeps it in scope.
When a child fails, correct the specification and follow up with that same child. The
primary spot-checks the actual diff and reruns the narrowest decisive acceptance subset;
it expands validation only when risk or impact warrants it. Lightweight or tightly
coupled changes may be implemented directly in the primary session.

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
when delegation adds value, monitors it, and keeps acceptance in the primary session.

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
those fields are available and emits only an allowlisted routing object. It rejects
missing or ambiguous metadata, including null/empty sandbox, permission, or
working-directory fields, and never prints prompts, tokens, secrets, or arbitrary
rollout payloads.

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
