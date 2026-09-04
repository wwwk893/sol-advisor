#!/bin/sh
set -eu

fail() { printf '%s\n' "FAIL: $*" >&2; exit 1; }
pass() { printf '%s\n' "PASS: $*"; }

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd) || exit 1
plugin_dir=$(CDPATH= cd "$script_dir/.." && pwd) || exit 1
skill=$plugin_dir/skills/orchestration/SKILL.md
contracts=$plugin_dir/skills/orchestration/references/role-contracts.md
native=$plugin_dir/skills/orchestration/references/native-v2-lane.md
cases=$plugin_dir/skills/orchestration/evals/model_routing_cases.json
readme=$(CDPATH= cd "$plugin_dir/../.." && pwd)/README.md
global_agents=${1-}

for required in "$skill" "$contracts" "$native" "$cases"; do
  test -f "$required" || fail "required file missing: $required"
done
command -v python3 >/dev/null 2>&1 || fail "python3 is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"
jq empty "$cases"

readme_arg=$readme
[ -f "$readme" ] || readme_arg=''
python3 - "$skill" "$contracts" "$native" "$readme_arg" "$cases" "$global_agents" <<'PY'
from pathlib import Path
import json
import sys

skill_path, contracts_path, native_path = map(Path, sys.argv[1:4])
readme_path = Path(sys.argv[4]) if sys.argv[4] else None
cases_path = Path(sys.argv[5])
global_path = Path(sys.argv[6]) if sys.argv[6] else None
docs = {
    "SKILL": skill_path.read_text(encoding="utf-8"),
    "role contracts": contracts_path.read_text(encoding="utf-8"),
    "native lane": native_path.read_text(encoding="utf-8"),
}
if readme_path is not None:
    docs["README"] = readme_path.read_text(encoding="utf-8")
if global_path is not None:
    docs["global AGENTS"] = global_path.read_text(encoding="utf-8")
fixture = json.loads(cases_path.read_text(encoding="utf-8"))
if fixture.get("suite") != "Sol Advisor 0.7.1 exact native routing holdout":
    raise SystemExit("wrong model routing suite")
if fixture.get("fork_turns") != "none":
    raise SystemExit("all model routes must use fork_turns=none")
policy = fixture.get("sol_route_policy")
if policy != {"fast_mode_request":"none", "service_tier_request":"none", "explicit_fast_or_priority":"block", "missing_runtime_fields":"unobservable"}:
    raise SystemExit("Sol fast/service-tier policy changed")

required_ids = {
    "bounded_subsystem_trace", "cross_repo_architecture_trace", "coherent_worker_phase",
    "ordinary_independent_review", "critical_risk_review", "browser_runtime_tester",
}
items = fixture.get("cases")
if not isinstance(items, list) or len(items) != len(required_ids):
    raise SystemExit("model routing cases have wrong cardinality")
seen = set()
fields = ("carrier_agent_type", "logical_role", "route_class", "model", "reasoning_effort")
for item in items:
    if not isinstance(item, dict) or not isinstance(item.get("id"), str):
        raise SystemExit("invalid model routing case")
    case_id = item["id"]
    if case_id in seen or case_id not in required_ids:
        raise SystemExit(f"duplicate or unknown model routing case: {case_id!r}")
    seen.add(case_id)
    if not all(isinstance(item.get(field), str) and item[field] for field in fields):
        raise SystemExit(f"model routing case {case_id} has incomplete route fields")
if seen != required_ids:
    raise SystemExit("model routing cases are incomplete")

matrix_tokens = []
for item in items:
    key = item["logical_role"]
    if key == "reviewer":
        key += "." + item["route_class"]
    matrix_tokens.append(
        f"{key}={item['carrier_agent_type']}/{item['model']}/{item['reasoning_effort']}/{item['route_class']}"
    )
required_tokens = (
    "agent_type=default", "agent_type=tester", "logical_role", "route_class",
    "gpt-5.6-sol", "gpt-5.6-luna", "fork_turns=none", "fast_mode=true",
    "service_tier=priority", "unobservable", "no silent fallback",
)
for label in ("SKILL", "role contracts", "native lane"):
    text = docs[label]
    missing = [token for token in required_tokens if token not in text]
    if missing:
        raise SystemExit(f"{label} missing routing token(s): {', '.join(missing)}")
    for forbidden in ("gpt-5.6-terra", "mechanical-fast-path", "request priority"):
        if forbidden.lower() in text.lower():
            raise SystemExit(f"{label} contains forbidden route token {forbidden!r}")
for label, text in docs.items():
    missing_matrix = [token for token in matrix_tokens if token not in text]
    if missing_matrix:
        raise SystemExit(f"{label} has an exact route mapping mismatch: {', '.join(missing_matrix)}")

mutation_surface = docs["SKILL"]
mutations = {
    "worker/reviewer effort swap": (
        ("worker=default/gpt-5.6-sol/medium/normal", "worker=default/gpt-5.6-sol/high/normal"),
        ("reviewer.critical-risk=default/gpt-5.6-sol/high/critical-risk", "reviewer.critical-risk=default/gpt-5.6-sol/medium/critical-risk"),
    ),
    "carrier swap": (("explorer=default/gpt-5.6-sol/low/normal", "explorer=tester/gpt-5.6-sol/low/normal"),),
    "tester effort swap": (("tester=tester/gpt-5.6-luna/max/normal", "tester=tester/gpt-5.6-luna/high/normal"),),
    "route class swap": (("reviewer.critical-risk=default/gpt-5.6-sol/high/critical-risk", "reviewer.critical-risk=default/gpt-5.6-sol/high/normal"),),
}
for name, replacements in mutations.items():
    mutated = mutation_surface
    for expected, replacement in replacements:
        if expected not in mutated:
            raise SystemExit(f"mutation self-test source missing {expected!r}")
        mutated = mutated.replace(expected, replacement, 1)
    if not any(token not in mutated for token in matrix_tokens):
        raise SystemExit(f"exact-matrix mutation self-test failed: {name}")

print("Sol Advisor 0.7.1 exact native routing matrix and 4 mutation classes are consistent")
PY

sh -n "$0"
pass "exact mixed Sol routing and no-fast/priority policy"
