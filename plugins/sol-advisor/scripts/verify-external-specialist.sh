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

if "Load references/external-specialist-lane.md only when that lane is admitted" not in skill:
    raise SystemExit("SKILL does not conditionally load the external specialist lane")

required_skill_tokens = (
    "not a sixth native role",
    "no production source ownership",
    "no silent fallback",
    "accept an admitted artifact before issuing a native `worker` packet",
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

# Keep the holdout descriptions and outcomes reviewable.  A route-only check would let a blank or
# silently rewritten case continue to pass while preserving the same id-to-route mapping.
expected = {
    "substantial_ui_artifact": {
        "text": "The interaction direction is unsettled; commission the exact configured design specialist to produce a rendered prototype before implementation.",
        "decision_owner": "sol",
        "route": "external-specialist",
        "expected_outcome": "Sol creates an isolated commission, inspects the required artifact, and accepts it before any native worker packet.",
    },
    "minor_ui_polish": {
        "text": "Adjust a settled spacing token in one already-inspected component.",
        "decision_owner": "sol",
        "route": "primary-or-worker",
        "expected_outcome": "Do not commission an external artifact; keep the settled micro-edit primary or send the coherent write phase to the native worker.",
    },
    "accepted_artifact_implementation": {
        "text": "The rendered design artifact and implementation handoff are accepted; implement the named production files and focused tests.",
        "decision_owner": "sol",
        "route": "worker",
        "expected_outcome": "A native worker owns production implementation; the external specialist receives no production source ownership.",
    },
    "exact_external_route_unavailable": {
        "text": "The user requires one exact external runtime and model, but that route is unavailable.",
        "decision_owner": "sol",
        "route": "blocked",
        "expected_outcome": "Report the exact blocker and never silently substitute another provider, model, native role, or permission mode.",
    },
    "succeeded_without_artifact": {
        "text": "The external run reports succeeded but does not contain the required deliverable.",
        "decision_owner": "sol",
        "route": "blocked",
        "expected_outcome": "Classify the run as succeeded-no-output and do not accept or issue an implementation packet.",
    },
}
required_case_fields = ("id", "text", "decision_owner", "route", "expected_outcome")
seen_ids = set()
seen_texts = set()
for index, item in enumerate(items):
    if not isinstance(item, dict):
        raise SystemExit(f"external specialist case {index} must be an object")
    missing = [field for field in required_case_fields if field not in item]
    if missing:
        raise SystemExit(
            f"external specialist case {index} is missing critical field(s): {', '.join(missing)}"
        )
    for field in required_case_fields:
        if not isinstance(item[field], str) or not item[field].strip():
            raise SystemExit(
                f"external specialist case {index} needs non-empty string {field}"
            )
    case_id = item["id"]
    if case_id in seen_ids:
        raise SystemExit(f"external specialist cases duplicate id {case_id!r}")
    if item["text"] in seen_texts:
        raise SystemExit(f"external specialist cases duplicate text at {case_id!r}")
    seen_ids.add(case_id)
    seen_texts.add(item["text"])
    expected_case = expected.get(case_id)
    if expected_case is None:
        raise SystemExit(f"external specialist cases contain unknown id {case_id!r}")
    for field in required_case_fields[1:]:
        if item[field] != expected_case[field]:
            raise SystemExit(
                f"external specialist case {case_id} changed critical {field}: "
                f"{item[field]!r} != {expected_case[field]!r}"
            )
if seen_ids != set(expected):
    raise SystemExit("external specialist cases do not cover the required ids exactly")

allocation_items = allocation.get("cases")
if allocation.get("suite") != "Sol-primary cognitive allocation holdout":
    raise SystemExit("native allocation fixture has the wrong suite name")
if not isinstance(allocation_items, list) or not allocation_items:
    raise SystemExit("native allocation fixture must contain a non-empty cases list")
allocation_fields = (
    "id", "text", "decision_owner", "execution_route", "luna_scope", "expected_outcome"
)
allocation_ids = set()
allocation_texts = set()

native_routes = {
    "primary", "blocked", "deep_explorer", "explorer", "worker", "tester", "reviewer"
}
for index, item in enumerate(allocation_items):
    if not isinstance(item, dict):
        raise SystemExit(f"native allocation case {index} must be an object")
    missing = [field for field in allocation_fields if field not in item]
    if missing:
        raise SystemExit(
            f"native allocation case {index} is missing critical field(s): {', '.join(missing)}"
        )
    for field in allocation_fields:
        if not isinstance(item[field], str) or not item[field].strip():
            raise SystemExit(f"native allocation case {index} needs non-empty string {field}")
    if item["id"] in allocation_ids or item["text"] in allocation_texts:
        raise SystemExit(f"native allocation case {index} duplicates an id or text")
    allocation_ids.add(item["id"])
    allocation_texts.add(item["text"])
    if item["decision_owner"] != "sol":
        raise SystemExit(f"native allocation case {item['id']} changed decision_owner")
    route = item["execution_route"]
    if route not in native_routes:
        raise SystemExit(f"native allocation fixture gained an external/sixth role: {route!r}")

for forbidden in ("agent_type=external", "agent_type=designer", "agent_type=claude"):
    if forbidden in skill or forbidden in lane:
        raise SystemExit(f"external specialist was incorrectly modeled as native role: {forbidden}")

print("external specialist lane preserves Sol ownership and the five-role native inventory")
PY

sh -n "$script_dir/verify-external-specialist.sh"
pass "external specialist contract, holdout cases, and shell syntax"
