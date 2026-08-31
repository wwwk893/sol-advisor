#!/bin/sh

set -eu

fail() {
  printf '%s\n' "FAIL: $*" >&2
  exit 1
}

pass() {
  printf '%s\n' "PASS: $*"
}

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd) || exit 1
plugin_dir=$(CDPATH= cd "$script_dir/.." && pwd) || exit 1
skill=$plugin_dir/skills/orchestration/SKILL.md
contracts=$plugin_dir/skills/orchestration/references/role-contracts.md
native=$plugin_dir/skills/orchestration/references/native-v2-lane.md
cases=$plugin_dir/skills/orchestration/evals/model_routing_cases.json

for required in "$skill" "$contracts" "$native" "$cases"; do
  test -f "$required" || fail "required file missing: $required"
done

command -v python3 >/dev/null 2>&1 || fail "python3 is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"
jq empty "$cases"

python3 - "$skill" "$contracts" "$native" "$cases" <<'PY'
from pathlib import Path
import json
import sys

skill_path, contracts_path, native_path, cases_path = map(Path, sys.argv[1:])
skill = skill_path.read_text(encoding="utf-8")
contracts = contracts_path.read_text(encoding="utf-8")
native = native_path.read_text(encoding="utf-8")
cases = json.loads(cases_path.read_text(encoding="utf-8"))

if cases.get("suite") != "Balanced native model routing holdout":
    raise SystemExit("model routing case suite has the wrong name")

expected = {
    "bounded_subsystem_trace": ("explorer", "default", "gpt-5.6-luna", "high"),
    "cross_repo_architecture_trace": ("deep_explorer", "default", "gpt-5.6-terra", "high"),
    "mechanical_two_file_worker": ("worker", "mechanical-fast-path", "gpt-5.6-luna", "high"),
    "normal_multifile_worker": ("worker", "normal", "gpt-5.6-terra", "high"),
    "cross_repo_worker": ("worker", "normal", "gpt-5.6-terra", "high"),
    "lockfile_disqualifies_fast_path": ("worker", "normal", "gpt-5.6-terra", "high"),
    "browser_runtime_tester": ("tester", "default", "gpt-5.6-luna", "high"),
    "ordinary_independent_review": ("reviewer", "normal", "gpt-5.6-sol", "medium"),
    "production_auth_review": ("reviewer", "critical-risk", "gpt-5.6-sol", "high"),
    "irreversible_migration_review": ("reviewer", "critical-risk", "gpt-5.6-sol", "high"),
}

items = cases.get("cases")
if not isinstance(items, list) or len(items) != len(expected):
    raise SystemExit(f"model routing cases must contain exactly {len(expected)} cases")

seen = set()
for index, item in enumerate(items):
    if not isinstance(item, dict):
        raise SystemExit(f"model routing case {index} must be an object")
    for field in (
        "id", "text", "agent_type", "route_class", "model", "reasoning_effort", "expected_outcome"
    ):
        if not isinstance(item.get(field), str) or not item[field].strip():
            raise SystemExit(f"model routing case {index} needs non-empty string {field}")
    case_id = item["id"]
    if case_id in seen:
        raise SystemExit(f"model routing cases duplicate id {case_id!r}")
    seen.add(case_id)
    expected_route = expected.get(case_id)
    if expected_route is None:
        raise SystemExit(f"model routing cases contain unknown id {case_id!r}")
    actual_route = (
        item["agent_type"], item["route_class"], item["model"], item["reasoning_effort"]
    )
    if actual_route != expected_route:
        raise SystemExit(
            f"model routing case {case_id} changed route: {actual_route!r} != {expected_route!r}"
        )

if seen != set(expected):
    raise SystemExit("model routing cases do not cover the required ids exactly")

allowed_models = {"gpt-5.6-luna", "gpt-5.6-terra", "gpt-5.6-sol"}
allowed_efforts = {"medium", "high"}
for item in items:
    if item["model"] not in allowed_models:
        raise SystemExit(f"unsupported model in routing cases: {item['model']!r}")
    if item["reasoning_effort"] not in allowed_efforts:
        raise SystemExit(f"unsupported effort in routing cases: {item['reasoning_effort']!r}")

for document, label in ((skill, "SKILL"), (contracts, "role contracts"), (native, "native lane")):
    for token in (
        "gpt-5.6-luna",
        "gpt-5.6-terra",
        "gpt-5.6-sol",
        "mechanical fast-path",
        "critical-risk",
        "fork_turns=none",
        "no silent fallback",
    ):
        if token.lower() not in document.lower():
            raise SystemExit(f"{label} is missing balanced-routing token {token!r}")
    if "reasoning_effort=max" not in document:
        raise SystemExit(f"{label} lost the 0.6.8 legacy-route verifier sentinel")
    if "forbidden" not in document.lower() or "uniform" not in document.lower():
        raise SystemExit(f"{label} must mark the previous uniform Luna/max route as forbidden")

for token in (
    "at most two files",
    "cross-package/cross-repository",
    "dependency/lockfile",
    "generated/legacy",
):
    if token.lower() not in skill.lower() or token.lower() not in contracts.lower():
        raise SystemExit(f"worker fast-path contract is missing {token!r}")

for token in (
    "production authentication",
    "access-control",
    "irreversible",
    "security-sensitive",
):
    if token.lower() not in skill.lower() or token.lower() not in contracts.lower():
        raise SystemExit(f"reviewer critical-risk contract is missing {token!r}")

print("balanced native model routing matrix and holdout cases are consistent")
PY

sh -n "$script_dir/verify-model-routing.sh"
pass "balanced native model routing contract, holdout cases, and shell syntax"
