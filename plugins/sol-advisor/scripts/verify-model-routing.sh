#!/bin/sh

set -eu

fail() { printf '%s\n' "FAIL: $*" >&2; exit 1; }
pass() { printf '%s\n' "PASS: $*"; }

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd) || exit 1
plugin_dir=$(CDPATH= cd "$script_dir/.." && pwd) || exit 1
skill=$plugin_dir/skills/orchestration/SKILL.md
contracts=$plugin_dir/skills/orchestration/references/role-contracts.md
native=$plugin_dir/skills/orchestration/references/native-v2-lane.md
readme=$plugin_dir/../../README.md
cases=$plugin_dir/skills/orchestration/evals/model_routing_cases.json

for required in "$skill" "$contracts" "$native" "$readme" "$cases"; do
  test -f "$required" || fail "required file missing: $required"
done

command -v python3 >/dev/null 2>&1 || fail "python3 is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"
jq empty "$cases"

python3 - "$skill" "$contracts" "$native" "$readme" "$cases" <<'PY'
from copy import deepcopy
from pathlib import Path
import json
import re
import sys

skill_path, contracts_path, native_path, readme_path, cases_path = map(Path, sys.argv[1:])
documents = {
    "SKILL": skill_path.read_text(encoding="utf-8"),
    "role contracts": contracts_path.read_text(encoding="utf-8"),
    "native lane": native_path.read_text(encoding="utf-8"),
    "README": readme_path.read_text(encoding="utf-8"),
}
suite = json.loads(cases_path.read_text(encoding="utf-8"))

MATRIX = {
    ("explorer", "default"): ("gpt-5.6-luna", "high"),
    ("deep_explorer", "default"): ("gpt-5.6-terra", "high"),
    ("worker", "mechanical-fast-path"): ("gpt-5.6-luna", "high"),
    ("worker", "normal"): ("gpt-5.6-terra", "high"),
    ("tester", "default"): ("gpt-5.6-luna", "high"),
    ("reviewer", "normal"): ("gpt-5.6-sol", "medium"),
    ("reviewer", "critical-risk"): ("gpt-5.6-sol", "high"),
}
MATRIX_ROWS = (
    "| `explorer` | `gpt-5.6-luna` | `high` |",
    "| `deep_explorer` | `gpt-5.6-terra` | `high` |",
    "| `worker` mechanical fast-path | `gpt-5.6-luna` | `high` |",
    "| `worker` normal | `gpt-5.6-terra` | `high` |",
    "| `tester` | `gpt-5.6-luna` | `high` |",
    "| `reviewer` normal | `gpt-5.6-sol` | `medium` |",
    "| `reviewer` critical-risk | `gpt-5.6-sol` | `high` |",
)
WORKER_FACTS = (
    "owned_files_known", "owned_file_count", "intent_settled", "interfaces_settled",
    "architecture_settled", "authorization_settled", "risk_settled", "acceptance_settled",
    "cross_package_or_repository", "dependency_or_lockfile_change",
    "tracked_config_migration", "generated_or_legacy_reconciliation",
    "writer_ownership_unambiguous", "focused_check_count",
)
PREREQUISITES = (
    "owned_files_known", "intent_settled", "interfaces_settled", "architecture_settled",
    "authorization_settled", "risk_settled", "acceptance_settled", "writer_ownership_unambiguous",
)
DISQUALIFIERS = (
    "cross_package_or_repository", "dependency_or_lockfile_change",
    "tracked_config_migration", "generated_or_legacy_reconciliation",
)
SETTLED_FACTS = PREREQUISITES[1:-1]
RISK_FACTS = (
    "production_authentication", "access_control", "secrets", "security_sensitive_privilege",
    "destructive_data_or_migration", "irreversible_data_or_migration", "credible_data_loss",
    "high_consequence_residual_risk",
)
API_FIELDS = (
    "agent_type=default",
    "model=<resolved gpt-5.6-luna|gpt-5.6-terra|gpt-5.6-sol>",
    "reasoning_effort=<resolved medium|high>",
    "fork_turns=none",
)
PACKET_FIELDS = (
    "carrier_agent_type=default",
    "logical_role=<deep_explorer|explorer|worker|tester|reviewer>",
    "route_class=<default|mechanical-fast-path|normal|critical-risk>",
    "model=<resolved gpt-5.6-luna|gpt-5.6-terra|gpt-5.6-sol>",
    "reasoning_effort=<resolved medium|high>",
    "fork_turns=none",
)

def fail(message):
    raise SystemExit(message)

def native_api_blocks(document):
    return re.findall(r"native spawn API[^\n]*\n\n```text\n(.*?)```", document, flags=re.IGNORECASE | re.DOTALL)

def packet_route_blocks(document):
    blocks = re.findall(r"```text\n(.*?)```", document, flags=re.DOTALL)
    return [block.split("ROUTE\n", 1)[1].split("\n\n", 1)[0] for block in blocks if "ROUTE\ncarrier_agent_type=default" in block]

def derive_worker_route(facts):
    if set(facts) != set(WORKER_FACTS):
        fail("worker routing facts have an invalid field set")
    for key in PREREQUISITES + DISQUALIFIERS:
        if type(facts[key]) is not bool and facts[key] is not None:
            fail(f"worker routing fact {key!r} must be boolean or null")
    for key in ("owned_file_count", "focused_check_count"):
        if type(facts[key]) is not int and facts[key] is not None:
            fail(f"worker routing count {key!r} must be integer or null")
    fast = (
        all(facts[key] is True for key in PREREQUISITES)
        and type(facts["owned_file_count"]) is int and 1 <= facts["owned_file_count"] <= 2
        and all(facts[key] is False for key in DISQUALIFIERS)
        and facts["focused_check_count"] == 1
    )
    return "mechanical-fast-path" if fast else "normal"

if suite.get("suite") != "Balanced native model routing holdout":
    fail("model routing case suite has the wrong name")
metadata = suite.get("metadata")
if not isinstance(metadata, str) or "text is unique reviewer context" not in metadata or "structured facts" not in metadata or "not prompt or model execution" not in metadata:
    fail("model routing suite metadata must describe structured routing and descriptive text limits")
items = suite.get("cases")
if not isinstance(items, list) or not items:
    fail("model routing cases must contain a non-empty cases list")

for label in ("SKILL", "role contracts", "native lane"):
    document = documents[label]
    for row in MATRIX_ROWS:
        if row not in document:
            fail(f"{label} is missing exact matrix row {row!r}")
    for token in ("agent_type=default", "logical_role", "route_class", "fork_turns=none"):
        if token not in document:
            fail(f"{label} is missing mixed-carrier field {token!r}")
    for forbidden in ("agent_type=<deep_explorer|explorer|worker|tester|reviewer>", "model=gpt-5.6-luna", "reasoning_effort=max", "uniform Luna/max"):
        if forbidden in document:
            fail(f"{label} retains unsupported mixed-lane route {forbidden!r}")

for label in ("README", "role contracts", "native lane"):
    document = documents[label]
    api_blocks = native_api_blocks(document)
    if len(api_blocks) != 1:
        fail(f"{label} must contain exactly one labeled native spawn API block")
    api_lines = tuple(line.strip() for line in api_blocks[0].strip().splitlines() if line.strip())
    if api_lines != API_FIELDS:
        fail(f"{label} native spawn API block must contain only actual spawn_agent arguments")
    routes = packet_route_blocks(document)
    if len(routes) != 1:
        fail(f"{label} must contain exactly one ROUTE packet block")
    route_lines = tuple(line.strip() for line in routes[0].strip().splitlines() if line.strip())
    if route_lines != PACKET_FIELDS:
        fail(f"{label} ROUTE packet block is incomplete or not separated from the spawn API")

seen_ids = set()
seen_texts = set()
worker_cases = []
reviewer_cases = []
roles_seen = set()
for index, item in enumerate(items):
    if not isinstance(item, dict):
        fail(f"model routing case {index} must be an object")
    for field in ("id", "text", "logical_role", "carrier_agent_type", "route_class", "model", "reasoning_effort"):
        if not isinstance(item.get(field), str) or not item[field].strip():
            fail(f"model routing case {index} needs non-empty string {field}")
    if "expected_outcome" in item or "agent_type" in item:
        fail(f"model routing case {item['id']!r} must keep only asserted routing fields")
    if item["id"] in seen_ids or item["text"] in seen_texts:
        fail(f"model routing cases duplicate an id or reviewer-context text")
    seen_ids.add(item["id"])
    seen_texts.add(item["text"])
    role = item["logical_role"]
    facts = item.get("facts")
    if not isinstance(facts, dict):
        fail(f"model routing case {item['id']!r} needs structured facts")
    if item["carrier_agent_type"] != "default":
        fail(f"model routing case {item['id']!r} must use the default carrier")

    if role == "worker":
        expected_class = derive_worker_route(facts)
        worker_cases.append(item)
    elif role == "reviewer":
        risk = facts.get("risk")
        if not isinstance(risk, dict) or set(risk) != set(RISK_FACTS) or any(type(risk[key]) is not bool for key in RISK_FACTS):
            fail(f"reviewer case {item['id']!r} has incomplete structured risk facts")
        expected_class = "critical-risk" if any(risk.values()) else "normal"
        reviewer_cases.append(item)
    elif role == "explorer":
        if facts != {"recon_scope": "bounded"}:
            fail(f"explorer case {item['id']!r} must be a bounded structured trace")
        expected_class = "default"
    elif role == "deep_explorer":
        if facts != {"recon_scope": "cross-package/cross-repository"}:
            fail(f"deep explorer case {item['id']!r} must be a cross-boundary structured trace")
        expected_class = "default"
    elif role == "tester":
        if facts != {"qa_scope": "browser/runtime"}:
            fail(f"tester case {item['id']!r} must be browser/runtime QA")
        expected_class = "default"
    else:
        fail(f"model routing case {item['id']!r} has unsupported logical role {role!r}")

    expected = MATRIX.get((role, expected_class))
    if expected is None or item["route_class"] != expected_class or (item["model"], item["reasoning_effort"]) != expected:
        fail(f"model routing case {item['id']!r} does not follow its structured route facts")
    roles_seen.add(role)

if roles_seen != {"explorer", "deep_explorer", "worker", "tester", "reviewer"}:
    fail("model routing fixtures must cover all five logical roles")
positive = [item for item in worker_cases if derive_worker_route(item["facts"]) == "mechanical-fast-path"]
if len(positive) != 1:
    fail("worker fixtures must contain exactly one positive mechanical fast-path")
canonical = positive[0]["facts"]
for key in SETTLED_FACTS:
    if not any(item["facts"] == {**canonical, key: False} for item in worker_cases):
        fail(f"worker fixtures miss isolated false coverage for {key!r}")
for key, value in (("owned_files_known", None), ("owned_file_count", 0), ("owned_file_count", 3), ("writer_ownership_unambiguous", False), ("focused_check_count", 2)):
    if not any(item["facts"] == {**canonical, key: value} for item in worker_cases):
        fail(f"worker fixtures miss isolated coverage for {key!r}={value!r}")
for key in DISQUALIFIERS:
    if not any(item["facts"] == {**canonical, key: True} for item in worker_cases):
        fail(f"worker fixtures miss isolated disqualifier coverage for {key!r}")
for key in WORKER_FACTS:
    mutated = deepcopy(canonical)
    mutated[key] = None
    if derive_worker_route(mutated) != "normal":
        fail(f"unknown worker fact {key!r} must route normal")
if not any(any(value is None for value in item["facts"].values()) for item in worker_cases):
    fail("worker fixtures must include an explicit unknown case")
if not any(not any(item["facts"]["risk"].values()) for item in reviewer_cases):
    fail("reviewer fixtures miss normal review coverage")
for key in RISK_FACTS:
    if not any(item["facts"]["risk"][key] and sum(item["facts"]["risk"].values()) == 1 for item in reviewer_cases):
        fail(f"reviewer fixtures miss isolated critical-risk coverage for {key!r}")

print(f"balanced native model routing matrix and structured holdout cases are consistent ({len(items)} cases)")
PY

sh -n "$script_dir/verify-model-routing.sh"
pass "balanced native model routing contract, API/packet separation, and structured holdout cases; static checks are not live spawn proof"
