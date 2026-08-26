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
lane=$plugin_dir/skills/orchestration/references/external-specialist-lane.md
cases=$plugin_dir/skills/orchestration/evals/external_specialist_cases.json
allocation=$plugin_dir/skills/orchestration/evals/allocation_cases.json

for required in "$skill" "$lane" "$cases" "$allocation"; do
  test -f "$required" || fail "required file missing: $required"
done

command -v python3 >/dev/null 2>&1 || fail "python3 is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"

jq empty "$cases"
jq empty "$allocation"

python3 - "$skill" "$lane" "$cases" "$allocation" <<'PY'
from pathlib import Path
import json
import sys

skill_path, lane_path, cases_path, allocation_path = map(Path, sys.argv[1:])
skill = skill_path.read_text(encoding="utf-8")
lane = lane_path.read_text(encoding="utf-8")
cases = json.loads(cases_path.read_text(encoding="utf-8"))
allocation = json.loads(allocation_path.read_text(encoding="utf-8"))

if "references/external-specialist-lane.md" not in skill:
    raise SystemExit("SKILL does not load the external specialist lane")

required_skill_tokens = (
    "not a sixth native role",
    "no production source ownership",
    "no silent fallback",
    "accept it before issuing a Luna `worker` packet",
)
for token in required_skill_tokens:
    if token not in skill:
        raise SystemExit(f"SKILL is missing {token!r}")

required_lane_tokens = (
    "exact provider/runtime/model/tool",
    "worktree state before and after",
    "stable idempotency/request identifier",
    "succeeded-no-output",
    "external correction counter is separate",
    "Do not implement production code",
    "native `worker` packet",
    "native `tester`",
)
for token in required_lane_tokens:
    if token.lower() not in lane.lower():
        raise SystemExit(f"external specialist lane is missing {token!r}")

items = cases.get("cases")
if cases.get("suite") != "Sol-owned external specialist holdout":
    raise SystemExit("external specialist case suite has the wrong name")
if not isinstance(items, list) or len(items) != 5:
    raise SystemExit("external specialist case suite must contain exactly five cases")
expected = {
    "substantial_ui_artifact": "external-specialist",
    "minor_ui_polish": "primary-or-worker",
    "accepted_artifact_implementation": "worker",
    "exact_external_route_unavailable": "blocked",
    "succeeded_without_artifact": "blocked",
}
actual = {item.get("id"): item.get("route") for item in items}
if actual != expected:
    raise SystemExit(f"external specialist routes changed: {actual!r}")
if any(item.get("decision_owner") != "sol" for item in items):
    raise SystemExit("every external specialist case must retain decision_owner=sol")

native_routes = {
    "primary", "blocked", "deep_explorer", "explorer", "worker", "tester", "reviewer"
}
for item in allocation.get("cases", []):
    route = item.get("execution_route")
    if route not in native_routes:
        raise SystemExit(f"native allocation fixture gained an external/sixth role: {route!r}")

for forbidden in ("agent_type=external", "agent_type=designer", "agent_type=claude"):
    if forbidden in skill or forbidden in lane:
        raise SystemExit(f"external specialist was incorrectly modeled as native role: {forbidden}")

print("external specialist lane preserves Sol ownership and the five-role native inventory")
PY

sh -n "$script_dir/verify-external-specialist.sh"
pass "external specialist contract, holdout cases, and shell syntax"
